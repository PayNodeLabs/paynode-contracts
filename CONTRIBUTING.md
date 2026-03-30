# Contributing to PayNode

Thank you for your interest in contributing to PayNode! This document provides guidelines for contributing to our stateless, non-custodial x402 payment router on Base.

## Code of Conduct

- Be respectful and constructive in all interactions
- Focus on improving the protocol's security and efficiency
- Respect the Business Source License terms
- Prioritize user safety and fund security

## Getting Started

### Prerequisites

- **Foundry** - For contract development and testing
- **Node.js 18+** - For SDK and tooling
- **Git** - For version control

### Installation

```bash
# Clone the repository
git clone https://github.com/PayNodeLabs/paynode-contracts.git
cd paynode-contracts

# Install Foundry dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

## Development Workflow

### Branch Naming

- `feat/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `security/description` - Security improvements

### Commit Messages

Follow conventional commits:
```
feat: add multi-token support to PayNodeRouter
fix: validate merchant address is not zero
 docs: update integration guide with examples
security: add reentrancy guard to pay() function
```

## Coding Standards

### Solidity

- Use Solidity ^0.8.19
- Follow the existing code style in `src/`
- All functions must have NatSpec comments
- Use OpenZeppelin contracts where applicable
- Gas optimization is critical - aim for <80k gas per payment

### Security Requirements

PayNode handles real value transfers. All contributions must:

1. **Never introduce storage writes** - Keep the stateless design
2. **Use SafeERC20** for all token transfers
3. **Validate all inputs** - Check addresses, amounts, deadlines
4. **Include comprehensive tests** - 100% coverage for payment flows
5. **Pass slither analysis** - Run `slither .` before submitting

### Testing

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test file
forge test --match-path test/PayNodeRouter.t.sol

# Run with coverage
forge coverage
```

## Areas for Contribution

### High Priority

- **Gas Optimization** - Further reduce gas costs while maintaining security
- **Additional Token Support** - Test with more ERC20 tokens
- **Integration Examples** - SDK examples in Python, Rust, Go
- **Documentation** - Better integration guides for merchants

### Medium Priority

- **Monitoring Tools** - Scripts to track payment events
- **Test Coverage** - Edge cases and fuzzing
- **Frontend Examples** - React/Vue integration demos

### Research

- **Cross-chain Payments** - Explore L2-to-L2 payment routing
- **Subscription Models** - Recurring payment patterns
- **Dispute Resolution** - Off-chain dispute mechanisms

## Submitting Changes

1. **Fork** the repository
2. **Create a branch** for your changes
3. **Write tests** for new functionality
4. **Run the test suite** - All tests must pass
5. **Update documentation** if needed
6. **Submit a Pull Request** with clear description

### PR Requirements

- Description explains what and why
- Links to any related issues
- All CI checks pass
- Code review approval from maintainers

## Security Disclosures

**Do NOT open public issues for security vulnerabilities.**

Instead, email security@paynode.xyz with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We follow responsible disclosure and will acknowledge within 48 hours.

## Questions?

- Open a [GitHub Discussion](https://github.com/PayNodeLabs/paynode-contracts/discussions)
- Join our community (link TBD)

## License

By contributing, you agree that your contributions will be licensed under the Business Source License 1.1.

---

**Thank you for helping build the future of M2M payments on Base!** 🚀
