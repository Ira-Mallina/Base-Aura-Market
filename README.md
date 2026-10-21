# Base Aura Market Hub

A high-performance decentralized marketplace protocol deployed on the Base L2 network. Aura Market Hub facilitates trustless peer-to-peer exchange of digital assets, integrating secure escrow mechanisms and automated royalty routing.

## Core Features
* **Trustless Escrow Settlement:** Eliminates counterparty risk by locking buyer funds in the contract until the asset transfer is cryptographically verified.
* **Automated Fee Splitting:** Seamlessly routes protocol fees and creator royalties in a single transaction, minimizing gas overhead for the end user.
* **Dynamic Listing Management:** Sellers retain full control over their active listings, with the ability to adjust pricing or cancel orders securely before execution.

## Security Architecture
Developed using Solidity `0.8.37`. The hub strictly enforces the Checks-Effects-Interactions pattern across all purchasing functions to completely neutralize reentrancy vectors during ETH transfers.
