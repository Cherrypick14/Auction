// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    address public seller;
    uint256 public startingBid;
    uint256 public endTime;
    bool public isActive;

    bool public fundsReleased; // Ensures funds are only released once
    address public highestBidder;
    uint256 public highestBid;
    
    mapping(address => uint256) public pendingReturns; // To store refunds  
    mapping(address => bool) public agreementConfirmed; // Tracks agreement status

    // Store the funds temporarily in the contract (escrow)
    mapping(address => uint256) public escrow;

    constructor(uint256 _startingBid, uint256 _duration) {
        seller = msg.sender;
        startingBid = _startingBid;
        endTime = block.timestamp + _duration;
        isActive = true;
        highestBid = _startingBid;
    }

    // Place a bid
    function bid() public payable {
        require(isActive, "Auction is not active");
        require(block.timestamp < endTime, "Auction has ended");
        require(msg.value > highestBid, "Bid too low");

        // Refund previous highest bidder
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Store the funds temporarily in escrow
        escrow[msg.sender] += msg.value;

        // Update highest bid and bidder
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
    
    // Withdraw funds if you're not the highest bidder
    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Finalize the auction and ensure the auction is ended
    function finalizeAuction() public {
        require(msg.sender == seller, "Only seller can finalize");
        require(block.timestamp >= endTime, "Auction not yet ended");
        require(isActive, "Auction already finalized");

        isActive = false;

        if (highestBidder != address(0)) {
            agreementConfirmed[seller] = false;
            agreementConfirmed[highestBidder] = false;
            fundsReleased = false;
        }
    }

    // Confirm the agreement and release the funds from escrow to the seller
    function confirmAgreement() public {
        require(msg.sender == seller || msg.sender == highestBidder, "Only seller or buyer can confirm");
        require(!fundsReleased, "Funds already released");

        agreementConfirmed[msg.sender] = true;

        if (agreementConfirmed[seller] && agreementConfirmed[highestBidder]) {
            fundsReleased = true;
            // Transfer the highest bid amount to the seller
            payable(seller).transfer(highestBid);
            // Clear the escrow for the highest bidder
            escrow[highestBidder] = 0;
        }
    }
}
