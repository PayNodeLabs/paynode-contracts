# PayNode Smart Contracts

基于 Solidity 开发的非托管 M2M (Machine-to-Machine) 支付路由合约，旨在为 AI Agent 提供极低延迟、高可验证性的支付基础设施。

## 📜 许可证 (License)

**Business Source License 1.1 (BSL-1.1)**
- 允许所有非商业用途及特定条件下的商业用途。
- 自发布起 2 年后自动转为 **GPL-3.0-or-later**。

## ⚡ Stateless 设计与 Gas 优势

`PayNodeRouter` 采用**无状态 (Stateless)** 架构设计，这是为了极致优化 M2M 场景下的 Gas 消耗：

1. **零存储 (No SSTORE):** 合约内部不维护 `orderId` 的结算状态。这意味着我们不需要在链上通过存储变量记录订单是否已付。
2. **事件驱动 (Event-driven):** 所有的支付证明均通过 `PaymentReceived` 事件抛出。
   - `orderId` 被定义为 `indexed`，方便 SDK/后端通过 Bloom Filter 快速检索。
3. **验证成本转移:** 支付的“真实性”由 SDK 侧与 RPC 交互验证。这使得单笔支付的 Gas 消耗仅为基本的转账操作 + 事件抛出（约 60k-80k Gas）。
4. **Gas 比较:** 相比于传统的托管/订单管理合约（通常需 150k+ Gas），PayNode 在 Base L2 上的执行成本降低了 50% 以上。

## 🔄 `pay()` 核心函数逻辑

`pay()` 函数是协议的主要入口点，执行流程如下：

1. **输入参数校验:** 
   - 确保 `merchant` 与 `token` 地址有效。
   - `amount` 必须大于 0。
2. **费率计算 (Protocol Fee Split):**
   - 协议目前设定 **1% (100 BPS)** 的固定费用。
   - `merchantAmount = amount * 99%`
   - `protocolFee = amount * 1%`
3. **原子性资产转移 (SafeERC20):**
   - 使用 `IERC20.safeTransferFrom` 从 `msg.sender` 处划扣资产。
   - 资产直接流向 `merchant` 地址。
   - 费率直接流向 `protocolTreasury` 地址。
4. **日志发射 (Emit Evidence):**
   - 抛出 `PaymentReceived(orderId, merchant, payer, token, amount, fee)`。
   - SDK 捕获此事件以确认支付状态。

## 🚀 进阶功能: `payWithPermit`

为了彻底消除 AI Agent 支付时的 "Two-Step Approval" (Approve + Transfer) 带来的 UX 摩擦与多重 Gas 消耗，协议支持 EIP-2612 Permit。Agent 仅需离线签名，SDK 即可在单笔交易中完成所有支付逻辑。

## 🛠️ 开发指南

使用 Foundry 套件进行测试与部署：

```bash
# 编译
forge build

# 运行全量测试 (包含 Fuzzing 测试)
forge test -vvv

# 部署至 Base Sepolia
forge script script/Deploy.s.sol --rpc-url $BASE_RPC --broadcast
```
