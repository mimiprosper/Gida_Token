// This contract is using 2 components,
// oppenzeppelin erc20 and openzeppelin ownable
// to build an erc20 token


#[starknet::contract]
pub mod TokenSale {
    use token_sales::interfaces::token_sale::ITokenSale;
    use openzeppelin::access::ownable::OwnableComponent; // import ownable component
    use openzeppelin::token::erc20::ERC20Component; // import erc20 component
    use openzeppelin::token::erc20::ERC20HooksEmptyImpl; // import erc20 component
    use starknet::{ContractAddress, get_caller_address};
    use core::num::traits::Zero;

    component!(
        path: ERC20Component, storage: erc20, event: ERC20Event
    ); // erc20 component path macro
    component!(
        path: OwnableComponent, storage: ownable, event: OwnableEvent
    ); // ownable component path macro

    // component internal implementation
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // component interaction with contract storage
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event] // component interaction with contract event
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    // constructor implementation
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.erc20.initializer("MyToken", "MTK");
        self.ownable.initializer(owner);
    }

    // custom errors
    pub mod Errors {
        pub const NOT_OWNER: felt252 = 'Caller is not the owner';
        pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller is the zero address';
    }

    // contract implementation
    #[abi(embed_v0)]
    impl TokenSaleImpl of ITokenSale<ContractState> {
        fn mint(ref self: ContractState, amount: u256) {
            // get the mint function caller
            let caller = get_caller_address();

            // assert caller is not address zero
            assert(!caller.is_non_zero(), Errors::ZERO_ADDRESS_CALLER);

            // owner is the caller
            assert(caller == owner, Errors::NOT_OWNER);

            // mint some token to owner
            self.erc20.mint(owner, amount);
        }
    }
}

