//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract LuxuryWatch is ERC1155, Ownable{
    error PaymentFailed();
    
    
    //mapping(uint256 the_id => uint256 tok_amt);
    mapping(uint256 => uint256) internal s_price_per_faction;
    mapping(uint256 => mapping(address => bool)) internal isForSale;
    mapping(uint256 => mapping(address => uint256)) public s_secondary_prices;
    string public baseuri = "https://api.luxwatchvault.com/v1/metadata/";
    uint256 public tok_id;
    struct WatchDetails {
        string watch_brand;
        string watch_model;
        string watch_serial;
        uint256 total_fractions;
        }
        WatchDetails [] s_watch_details_info;
        event WatchResgisteredandMinted(address indexed minter, uint256 indexed amount, uint256 indexed mint_id);
        event WatchtokenTransfered(address indexed buyer, uint256 indexed amounts);
        event PhysicalRedemptionRequested(address indexed redeemer, uint256 indexed watchId);
    constructor() ERC1155("") Ownable(msg.sender) {
        tok_id = 0;
    }



   function registerAndMintWatch(uint256 mint_amt, string memory brand, string memory model, string memory serial, uint256 initial_per_price) public {
        s_watch_details_info.push(WatchDetails(brand, model, serial, mint_amt));
        s_price_per_faction[tok_id] = initial_per_price;
        _mint(msg.sender, tok_id, mint_amt, "");
        isForSale[tok_id][msg.sender] = false;
        emit WatchResgisteredandMinted(msg.sender, mint_amt, tok_id);
        tok_id++;
 }

 function TransferTokenWatchFromVault(uint256 token_id, uint256 buy_amount) public payable {
    require(isForSale[token_id][owner()] == true, "Token Not for Sale");
    uint256 buy_value = SetWatchPrice(token_id, buy_amount);
    require(msg.value >= buy_value, "Insufficient amount");
    require(balanceOf(owner(), token_id) >= buy_amount);
    _safeTransferFrom(owner(), msg.sender, token_id, buy_amount, "");
    isForSale[token_id][msg.sender] = false;
    emit WatchtokenTransfered(msg.sender, buy_amount);
    (bool success,) = payable(owner()).call{value: buy_value}("");
    if(!success) {
        revert PaymentFailed();
    }
   
    }

function TransferTokenWatchfromUser(address from, uint256 _id_, uint256 am_t) public payable {
    // 1. Check if the specific seller ('from') has enabled the sale
    require(isForSale[_id_][from] == true, "Seller has not listed this asset");
    
    // 2. Use your existing SetWatchPrice helper
    // NEW: Use the seller's custom price
    uint256 sellerPrice = s_secondary_prices[_id_][from];
    // Fallback to vault price if they didn't set a custom one
    if (sellerPrice == 0) { sellerPrice = s_price_per_faction[_id_]; }
    
    uint256 _the_price = sellerPrice * am_t;
    require(msg.value == _the_price, "Incorrect ETH amount sent");
    // 4. The Transfer
    // Ensure 'from' has approved the contract before this is called!
    _safeTransferFrom(from, msg.sender, _id_, am_t, "");

    isForSale[_id_][msg.sender] = false;

    // 5. Forward payment to the SELLER (the 'from' address)
    (bool callsuccess,) = payable(from).call{value: msg.value}("");
    if(!callsuccess) {
        revert PaymentFailed();
    }

    emit WatchtokenTransfered(msg.sender, am_t);

    // 6. Cleanup: If seller is empty, turn off the sale flag
    if (balanceOf(from, _id_) == 0) {
        isForSale[_id_][from] = false;
    }
}

function TransferTokenWatchBatchFromVault(
    uint256[] memory ids, 
    uint256[] memory amounts
) public payable {
    require(ids.length == amounts.length, "Arrays must match");

    uint256 totalGrandCost = 0;

    for (uint256 i = 0; i < ids.length; i++) {
        uint256 id = ids[i];
        uint256 amount = amounts[i];

        // Check if the Vault has listed THIS specific watch
        require(isForSale[id][owner()] == true, "One or more tokens not for sale");

        // NEW: Check inventory inside the loop (Fixes the forge error)
        require(balanceOf(owner(), id) >= amount, "Vault inventory too low");

        // Add to total cost
        totalGrandCost += (s_price_per_faction[id] * amount);

        // Reset the buyer's sale flag
        isForSale[id][msg.sender] = false;
    }

    // Verification
    require(msg.value >= totalGrandCost, "Insufficient total ETH sent");

    // THE ACTION: Standard internal batch transfer call
    _safeBatchTransferFrom(owner(), msg.sender, ids, amounts, "");

    // Payment Forwarding
    (bool success,) = payable(owner()).call{value: totalGrandCost}("");
    if(!success) revert PaymentFailed();
}

function TransferTokenWatchBatchFromUser(
    address from,
    uint256[] memory ids, 
    uint256[] memory amounts
) public payable {
    require(ids.length == amounts.length, "Arrays must match");

    uint256 totalGrandCost = 0;

    for (uint256 i = 0; i < ids.length; i++) {
        uint256 id = ids[i];
        uint256 amount = amounts[i];

        require(isForSale[id][from] == true, "Seller has not listed one of these items");
        require(balanceOf(from, id) >= amount, "Seller inventory too low");

        // NEW LOGIC: Pull the price set by THIS specific seller
        uint256 sellerPricePerFraction = s_secondary_prices[id][from];
        
        // Fallback: If seller hasn't set a secondary price, use the original vault price
        if (sellerPricePerFraction == 0) {
            sellerPricePerFraction = s_price_per_faction[id];
        }

        totalGrandCost += (sellerPricePerFraction * amount);

        // Security & Cleanup
        isForSale[id][msg.sender] = false;
        if (balanceOf(from, id) == amount) {
            isForSale[id][from] = false; 
        }
    }

    require(msg.value == totalGrandCost, "Incorrect total ETH sent");

    _safeBatchTransferFrom(from, msg.sender, ids, amounts, "");

    (bool success,) = payable(from).call{value: totalGrandCost}("");
    if(!success) revert PaymentFailed();

    // emit BatchWatchtokenTransfered(msg.sender, ids, amounts);
}
 
function redeemForPhysical(uint256 _id) public {
    // 1. Validation: Ensure the watch exists in your array
    require(_id < s_watch_details_info.length, "Watch does not exist");

    // 2. The Logic: Look up the 100% threshold we saved in the struct
    uint256 totalRequired = s_watch_details_info[_id].total_fractions;
    
    // 3. Balance Check: Does the user actually own every single piece?
    uint256 userBalance = balanceOf(msg.sender, _id);
    require(userBalance == totalRequired, "Must own 100% of fractions to redeem");

    // 4. The Action: Burn the digital tokens (removes them from circulation forever)
    _burn(msg.sender, _id, userBalance);

    // 5. Cleanup: Turn off the "For Sale" status for good
    isForSale[_id][msg.sender] = false;

    // 6. Notification: Tell the vault owner to ship the watch
    emit PhysicalRedemptionRequested(msg.sender, _id);
}

 function uri(uint256 id) override public view returns(string memory) {
        require(id < s_watch_details_info.length, "Watch does not exist");
         WatchDetails memory item = s_watch_details_info[id];
         return (string.concat(baseuri, 
        item.watch_brand, "/", 
        item.watch_model, "/", 
        item.watch_serial, 
        ".json")
         );

 }

 function SetWatchPrice(uint256 _id, uint256 amounts_) public view returns(uint256 watch_price) {
          uint256 price_per_fraction = s_price_per_faction[_id];
          watch_price = price_per_fraction * amounts_;
          return watch_price;
 }

 function UpdateChoice(uint256 the_token_id, address decider, bool decision) private {
       isForSale[the_token_id][decider] = decision;
 }

 function setFractionPrice(uint256 _id, uint256 _newPricePerFraction) public {
    require(balanceOf(msg.sender, _id) > 0, "You do not own this watch");
    s_secondary_prices[_id][msg.sender] = _newPricePerFraction;
    
    // Automatically set to for sale once a price is set 
    //isForSale[_id][msg.sender] = true;
}

 function getWatchDetails(uint256 _id) public view returns (string memory brand, string memory model, string memory serial, uint256 totalFractions) {
    require(_id < s_watch_details_info.length, "Watch does not exist");
    WatchDetails memory item = s_watch_details_info[_id];
    return (item.watch_brand, item.watch_model, item.watch_serial, item.total_fractions);
 }

 function getWatchCount() public view returns (uint256) {
    return s_watch_details_info.length;
 }

}
