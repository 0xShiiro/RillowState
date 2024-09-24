//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Escrow {
    address public lender;
    address payable public seller;
    address public inspector;
    address public nftAddress;
    mapping(uint256 => bool) isListed;
    mapping(uint256 => address) public buyer;
    mapping(uint256 => uint256) public EscrowAmount;
    mapping(uint256 => uint256) public PurchaseAmount;
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) approval;

    constructor(
        address _nftaddress,
        address _seller,
        address _lender,
        address _inspector
    ) {
        lender = _lender;
        seller = payable(_seller);
        inspector = _inspector;
        nftAddress = _nftaddress;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Not the owner");
        _;
    }
    modifier onlyBuyer(uint256 _nftId) {
        require(msg.sender == buyer[_nftId], "Not the buyer");
        _;
    }
    modifier onlyInspector() {
        require(msg.sender == inspector, "Not the inspector");
        _;
    }

    function list(
        uint256 _Nftid,
        address _buyer,
        uint256 _escrowamount,
        uint256 _purchaseamount
    ) public onlySeller {
        IERC721(nftAddress).transferFrom(seller, address(this), _Nftid);
        isListed[_Nftid] = true;
        buyer[_Nftid] = _buyer;
        EscrowAmount[_Nftid] = _escrowamount;
        PurchaseAmount[_Nftid] = _purchaseamount;
    }

    function depositEarnest(uint256 _nftId) public payable onlyBuyer(_nftId) {
        require(msg.value >= EscrowAmount[_nftId], "Invalid Amount");
    }

    function inspectionpassed(
        uint256 _nftId,
        bool _passed
    ) public onlyInspector {
        inspectionPassed[_nftId] = _passed;
    }

    receive() external payable {}

    function getbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function approveSale(uint256 _nftId) public {
        approval[_nftId][msg.sender] = true;
    }

    function finalizeSale(uint256 _nftId) public {
        require(inspectionPassed[_nftId], "Inspection not passed");
        require(approval[_nftId][seller], "Not approved by seller");
        require(approval[_nftId][inspector], "Not approved by seller");
        require(approval[_nftId][buyer[_nftId]], "Not approved by buyer");
        isListed[_nftId] = false;
        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftId], _nftId);
    }

    function CancelSale(uint256 _nftId) public {
        if (inspectionPassed[_nftId] == false) {
            payable(buyer[_nftId]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
}
