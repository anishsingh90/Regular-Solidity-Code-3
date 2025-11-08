// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Payroll{
    address public owner;

    struct Employee{
        address wallet;
        uint256 salary;
        uint256 lastPaid;
        bool exists;
    }

    mapping (address => Employee) public employees;

    event EmployeeAdded(address indexed wallet, uint256 salary);
    event SalaryPaid(address indexed wallet, uint256 amount, uint256 date);

    modifier onlyOwner(){
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function addEmployee(address _wallet, uint256 _salary) external onlyOwner{
        require(!employees[_wallet].exists, "Employee already exists");
        employees[_wallet] = Employee(_wallet, _salary, 0, true);
        emit EmployeeAdded(_wallet, _salary);
    }

    function paySalary(address _wallet) external onlyOwner{
        Employee storage emp = employees[_wallet];
        require(emp.exists, "Employee not found");
        require(address(this).balance >= emp.salary, "Insufficient contract balance");

        emp.lastPaid = block.timestamp;
        payable (emp.wallet).transfer(emp.salary);
        emit SalaryPaid(_wallet, emp.salary, block.timestamp);
    }

    function getEmployee(address _wallet) external view returns(uint256 salary, uint256 lastPaid){
        require(employees[_wallet].exists, "Employee not found");
        Employee memory emp = employees[_wallet];
        return (emp.salary, emp.lastPaid);
    }

    //Allow contract to receive ETH
    receive() external payable {}
}
