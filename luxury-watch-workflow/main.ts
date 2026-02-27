import { 
	bytesToHex,
	cre,
	getNetwork,
	type HTTPPayload,
	hexToBase64,
	Runner,
	type Runtime,
	TxStatus,
} from '@chainlink/cre-sdk'
import { encodeAbiParameters, parseAbiParameters } from 'viem'
import { z } from 'zod'

// ========================================
// CONFIG SCHEMA
// ========================================
const configSchema = z.object({
	evms: z.array(
		z.object({
			luxuryWatchAddress: z.string(),
			consumerAddress: z.string(),
			chainSelectorName: z.string(),
			gasLimit: z.string(),
		}),
	),
})

type Config = z.infer<typeof configSchema>

// ========================================
// HTTP TRIGGER PAYLOAD SCHEMA
// ========================================
// Luxury watch registration/minting payload
const watchPayloadSchema = z.object({
	watchBrand: z.string(),
	watchModel: z.string(),
	watchSerial: z.string(),
	totalFractions: z.number(),
	pricePerFractionWei: z.string(),
	appraisalSource: z.string().optional(),
})

type WatchPayload = z.infer<typeof watchPayloadSchema>

// ========================================
// DUMMY OFF-CHAIN APPRAISAL DATA
// ========================================
// In production, this would be fetched from a real appraisal API / oracle
const DUMMY_APPRAISALS: Record<string, { appraised: boolean; valueUSD: number; certifiedBy: string }> = {
	'RLX-116500-ABC123': { appraised: true, valueUSD: 35000, certifiedBy: 'WatchCert Labs' },
	'AP-15500ST-XYZ789': { appraised: true, valueUSD: 45000, certifiedBy: 'Horology Auth Inc' },
	'PP-5711A-DEF456': { appraised: true, valueUSD: 120000, certifiedBy: 'WatchCert Labs' },
}

// Utility function to safely stringify objects with bigints
const safeJsonStringify = (obj: any): string =>
	JSON.stringify(obj, (_, value) => (typeof value === 'bigint' ? value.toString() : value), 2)

// ========================================
// OFF-CHAIN APPRAISAL VALIDATION (DUMMY)
// ========================================
const validateAppraisal = (
	runtime: Runtime<Config>,
	serial: string,
): boolean => {
	runtime.log('\n[Appraisal Validation] Checking off-chain watch authentication...')

	// Build a lookup key from serial
	const appraisal = DUMMY_APPRAISALS[serial]

	if (appraisal) {
		runtime.log(`✓ Watch found in appraisal database:`)
		runtime.log(`  - Value: $${appraisal.valueUSD.toLocaleString()} USD`)
		runtime.log(`  - Certified by: ${appraisal.certifiedBy}`)
		runtime.log(`  - Status: AUTHENTICATED`)
		return true
	}

	// For any serial not in our dummy data, auto-approve for demo purposes
	runtime.log(`⚠ Watch serial "${serial}" not in appraisal database.`)
	runtime.log(`  - Auto-approving for demo purposes (production would reject)`)
	runtime.log(`  - Estimated value: $10,000 USD (default)`)
	return true
}

// ========================================
// SUBMIT WATCH REGISTRATION REPORT
// ========================================
const submitWatchRegistration = (
	runtime: Runtime<Config>,
	evmClient: cre.capabilities.EVMClient,
	watchData: WatchPayload,
): string => {
	const evmConfig = runtime.config.evms[0]

	runtime.log(`\n[Watch Registration] Submitting on-chain registration...`)
	runtime.log(`  Brand: ${watchData.watchBrand}`)
	runtime.log(`  Model: ${watchData.watchModel}`)
	runtime.log(`  Serial: ${watchData.watchSerial}`)
	runtime.log(`  Fractions: ${watchData.totalFractions}`)
	runtime.log(`  Price/Fraction: ${watchData.pricePerFractionWei} wei`)

	// Encode report data matching WatchMintingConsumer._processReport():
	// (uint256 fractions, string brand, string model, string serial, uint256 pricePerFraction)
	const reportData = encodeAbiParameters(
		parseAbiParameters('uint256 fractions, string brand, string model, string serial, uint256 pricePerFraction'),
		[
			BigInt(watchData.totalFractions),
			watchData.watchBrand,
			watchData.watchModel,
			watchData.watchSerial,
			BigInt(watchData.pricePerFractionWei),
		],
	)

	runtime.log(`Encoded report data: ${reportData.slice(0, 66)}...`)

	// Generate DON-signed report using consensus capability
	const reportResponse = runtime
		.report({
			encodedPayload: hexToBase64(reportData),
			encoderName: 'evm',
			signingAlgo: 'ecdsa',
			hashingAlgo: 'keccak256',
		})
		.result()

	// Submit report to WatchMintingConsumer via Forwarder
	const resp = evmClient
		.writeReport(runtime, {
			receiver: evmConfig.consumerAddress,
			report: reportResponse,
			gasConfig: {
				gasLimit: evmConfig.gasLimit,
			},
		})
		.result()

	const txStatus = resp.txStatus

	if (txStatus !== TxStatus.SUCCESS) {
		throw new Error(`Failed to write report: ${resp.errorMessage || txStatus}`)
	}

	const txHash = resp.txHash || new Uint8Array(32)
	const txHashHex = bytesToHex(txHash)

	runtime.log(`⚠️  Report delivered to consumer at txHash: ${txHashHex}`)
	runtime.log(`   Verify execution: https://sepolia.etherscan.io/tx/${txHashHex}`)

	return txHashHex
}

// ========================================
// HTTP TRIGGER HANDLER
// ========================================
const onHTTPTrigger = (runtime: Runtime<Config>, evmClient: cre.capabilities.EVMClient, payload: HTTPPayload): string => {
	runtime.log('=== Luxury Watch Tokenization Workflow ===')
	runtime.log('Raw HTTP trigger received')

	// Require payload
	if (!payload.input || payload.input.length === 0) {
		throw new Error('HTTP trigger payload is required')
	}

	// Log the raw JSON for debugging
	runtime.log(`Payload bytes: ${payload.input.toString()}`)

	try {
		// Parse watch registration payload
		const payloadJson = JSON.parse(payload.input.toString())
		const watchData = watchPayloadSchema.parse(payloadJson)

		runtime.log(`Parsed watch payload: ${safeJsonStringify(watchData)}`)

		// ========================================
		// STEP 1: Off-chain Appraisal Validation (Dummy)
		// ========================================
		runtime.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
		runtime.log('STEP 1: Off-chain Watch Appraisal Validation')
		runtime.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

		const isValid = validateAppraisal(runtime, watchData.watchSerial)
		if (!isValid) {
			throw new Error(`Appraisal validation failed for serial: ${watchData.watchSerial}`)
		}

		// ========================================
		// STEP 2: Submit On-Chain Registration
		// ========================================
		runtime.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
		runtime.log('STEP 2: On-chain Watch Registration & Minting')
		runtime.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

		const txHash = submitWatchRegistration(runtime, evmClient, watchData)

		runtime.log(`\n✓ Watch tokenization complete!`)
		runtime.log(`  Brand: ${watchData.watchBrand}`)
		runtime.log(`  Model: ${watchData.watchModel}`)
		runtime.log(`  Serial: ${watchData.watchSerial}`)
		runtime.log(`  Fractions minted: ${watchData.totalFractions}`)
		runtime.log(`  TX: ${txHash}`)

		return `Watch registered and tokenized: ${watchData.watchBrand} ${watchData.watchModel} (${watchData.totalFractions} fractions) - TX: ${txHash}`

	} catch (error) {
		runtime.log(`Failed to process watch registration: ${error}`)
		throw new Error(`Failed to process watch registration: ${error}`)
	}
}

// ========================================
// WORKFLOW INITIALIZATION
// ========================================
const initWorkflow = (config: Config) => {
	const httpTrigger = new cre.capabilities.HTTPCapability()

	// Initialize EVM client for the configured chain
	const network = getNetwork({
		chainFamily: 'evm',
		chainSelectorName: config.evms[0].chainSelectorName,
		isTestnet: true,
	})

	if (!network) {
		throw new Error(
			`Network not found for chain selector name: ${config.evms[0].chainSelectorName}`,
		)
	}

	const evmClient = new cre.capabilities.EVMClient(network.chainSelector.selector)

	return [
		cre.handler(httpTrigger.trigger({}), (runtime, payload) => 
			onHTTPTrigger(runtime, evmClient, payload)
		),
	]
}

export async function main() {
	const runner = await Runner.newRunner<Config>({
		configSchema,
	})
	await runner.run(initWorkflow)
}

main()
