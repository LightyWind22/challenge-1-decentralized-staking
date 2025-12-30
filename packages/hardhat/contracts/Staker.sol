// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool private openForWithdraw = false;

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    // Khai báo Event để Frontend biết ai vừa nạp tiền
    event Stake(address indexed, uint256 amount);

    function stake() public payable {
        // Cập nhật số dư cá nhân
        balances[msg.sender] += msg.value;

        // Bắn sự kiện ra cho frontend
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public {
        // Kiểm tra đã hết deadline chưa
        if (block.timestamp >= deadline) {
            
            // Kiểm tra tổng tiền trong contract đã đạt ngưỡng chưa
            if (address(this).balance >= threshold) {
                // Đủ tiền -> gửi sang external contract
                exampleExternalContract.complete{value: address(this).balance}();
            } else {
                // Chưa đủ tiền -> mở cửa cho phép rút tiền về
                openForWithdraw = true;
            }
        }

    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public {
        // Kiểm tra đã được rút tiền chưa
        require(openForWithdraw == true, "Not open for withdraw yet");

        // Lấy số tiền người gọi đã đóng góp
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No balance to withdraw");

        // Reset số dư về 0 trước khi chuyển tiền
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send Ether");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0; // Đã hết giờ
        }
        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    // Hàm receive() đặc biệt:
    // 1. external: Chỉ có thể được gọi từ bên ngoài contract
    // 2. payable: Cho phép nhận ETH
    receive() external payable {
        stake();
    }

}
