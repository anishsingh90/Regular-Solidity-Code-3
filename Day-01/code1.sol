// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    enum Stage { Created, Manufactured, Shipped, Received, Sold }

    struct Product {
        uint id;
        string name;
        string origin;
        address currentOwner;
        Stage stage;
        uint timestamp;
    }

    mapping(uint => Product) public products;
    address public owner;

    event ProductAdded(uint id, string name, string origin, address indexed owner);
    event ProductTransferred(uint id, address indexed from, address indexed to, Stage stage);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier onlyProductOwner(uint _id) {
        require(products[_id].currentOwner == msg.sender, "Not the product owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addProduct(uint _id, string memory _name, string memory _origin) public onlyOwner {
        require(products[_id].id == 0, "Product already exists");
        products[_id] = Product({
            id: _id,
            name: _name,
            origin: _origin,
            currentOwner: msg.sender,
            stage: Stage.Created,
            timestamp: block.timestamp
        });

        emit ProductAdded(_id, _name, _origin, msg.sender);
    }

    function transferProduct(uint _id, address _newOwner, Stage _newStage) public onlyProductOwner(_id) {
        require(_newOwner != address(0), "Invalid new owner");
        products[_id].currentOwner = _newOwner;
        products[_id].stage = _newStage;
        products[_id].timestamp = block.timestamp;

        emit ProductTransferred(_id, msg.sender, _newOwner, _newStage);
    }

    function getProduct(uint _id) public view returns (
        uint,
        string memory,
        string memory,
        address,
        Stage,
        uint
    ) {
        Product memory p = products[_id];
        require(p.id != 0, "Product does not exist");
        return (p.id, p.name, p.origin, p.currentOwner, p.stage, p.timestamp);
    }
}
