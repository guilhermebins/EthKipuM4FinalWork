// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 * @dev The KipuBank is a contract for ETH deposits and withdrawals.
 *      Includes a bank cap, user deposits, balance and withdrawal limits.
 * @notice This contract is about the Module 4 - final exam by Etherium Developer Pack - São Paulo course.
 *         With mentor Patrick Carneiro "Barba" (CEO 77 Inovation Labs) sponsored for ETH KIPU and ERC55.
 */
contract KipuBank {

    /// @notice The immutables i_bankCap, set during deployment.
    uint256 immutable i_bankCap;

    /// @notice This limit is set to prevent large withdrawals in a single transaction. The default value is set to 1 ether.
    uint256 constant WITHDRAW_LIMIT = 1 ether;

    /// @notice The total amount of ETH deposited in the KipuBank.
    uint256 public s_totalDeposited;

    /// @notice The mapping that tracks the balance of each user.
    mapping(address => uint256) public s_userBank;

    /// @notice The events is emitted when a deposit or withdrawal ETH is successfully.
    event KipuBank_DepositSuccessful(address indexed _user, uint256 _amount);
    event KipuBank_WithdrawSuccessful(address indexed _user, uint256 _amount);

    /// @notice The errors are used to revert transactions with specific messages.
    error KipuBank_AmountExceedsBankCap(string _valueExceeds, uint256 _bankCap, string _limitExceeds, uint256 _totalBalance);
    error KipuBank_AmountExceedsUserBalance(string _valueExceeds, uint256 _amount, string _currentUserBalance, uint256 _userBalance);
    error KipuBank_AmountExceedsWithdrawLimit(string _valueExceeds, uint256 _amount, string _limitExceeds, uint256 _limit);
    error KipuBank_TransferFailed(string _message, address _to, uint256 _amount, uint256 _balance);

    /// @notice The modifier is used to check if the amount is within the user's balance and the withdraw limit.
    modifier amountCheck(uint256 _amount) {
        if(_amount > s_userBank[msg.sender])
            revert KipuBank_AmountExceedsUserBalance(
                "Amount Exceeds: ", _amount, "Current User Balance: ", s_userBank[msg.sender]
            );
        if(_amount > WITHDRAW_LIMIT)
            revert KipuBank_AmountExceedsWithdrawLimit(
                "Amount Exceeds: ", _amount, "Withdraw Limit: ", WITHDRAW_LIMIT
            );
        _;
    }

    /**
     * @notice The constructor sets the KipuBank cap.
     * @param / _deployer / The address of the deployer. Requered by Scaffold to running locally.
     * @param _bankCap The KipuBank cap. This is the maximum amount of ETH that can be all users deposited in the KipuBank.
     */
    constructor(
        address /* _deployer */,
        uint256 _bankCap
    ) {
        i_bankCap = _bankCap;
    }

    /**
     * @notice Deposits ETH into the KipuBank.
     * @dev Checks if the deposit amount exceeds the bank cap.
     *      Updates the user's balance and emits a `DepositSuccessful` event.
     */
    function deposit() external payable {
        s_totalDeposited = s_totalDeposited + msg.value;
        if (s_totalDeposited > i_bankCap) 
            revert KipuBank_AmountExceedsBankCap(
                "Bank Cap: ", i_bankCap, "Limit Exceeds: ", s_totalDeposited
            );
            
        s_userBank[msg.sender] = s_userBank[msg.sender] + msg.value;
        
        emit KipuBank_DepositSuccessful(
            msg.sender, msg.value
        );
    }

    /**
     * @notice Withdraws ETH from the KipuBank.
     * @param _amount The amount of ETH to withdraw.
     * @dev The amount is checked against the user's balance and the withdraw limit.
     *      If the amount exceeds either limit, an error is thrown.
     *      The `_processWithdraw` function is called to handle the transfer.
     */
    function withdraw(uint256 _amount) external amountCheck(_amount) {
        _processWithdraw(_amount);
    }

    /**
     * @notice Internal function to process the withdrawal.
     * @param _amount The amount of ETH to withdraw.
     * @dev Updates the user's balance and transfers the ETH to the user.
     *      If the transfer fails, an error is thrown.
     *      Emits a `WithdrawSuccessful` event.
     * @dev It is used to handle the transfer of ETH to the user after checking the amount.
     *      The function is marked as private to prevent external calls.
     *      This is a security measure to ensure that the transfer can only be initiated by the contract itself.
     */
    function _processWithdraw(uint256 _amount) private {
        s_userBank[msg.sender] = s_userBank[msg.sender] - _amount;
        s_totalDeposited = s_totalDeposited - _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");

        if (!success)
            revert KipuBank_TransferFailed(
                "Transfer Failed", msg.sender, _amount, address(this).balance
            );

        emit KipuBank_WithdrawSuccessful(
            msg.sender, _amount
        );
    }

    /// @notice Returns the KipuBank cap.
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
