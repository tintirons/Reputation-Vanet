# Dynamic Reputation Computation and Management Model for VANET Using a Smart Contract

This repository provides the prototype design of smart contract for dynamic reputation computation and management in VANET.

The smart contract contains multi-signature confirmation function for owner related functions such as node registration, deletion, and multi-signatures parameter update.

The reputation computation model incorporate various techniques to provide resistant against reputation manipulation attacks which are weighted voting, exponential trust decay, trust maturity, event lifetime checking, event criticality level factor, penalty factor, and fuzzy logic. 

The smart contract automatically compute vehicles' reputation score when they submit new event and will reject the new event if the submitting vehicles have reputation score lower than the requirement for the event type.
