// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Diamond} from "src/upgradeability/diamond/Diamond.sol";

import {
    DiamondCutFacet
} from "src/upgradeability/diamond/facets/DiamondCutFacet.sol";
import {
    DiamondLoupeFacet
} from "src/upgradeability/diamond/facets/DiamondLoupeFacet.sol";
import {Test1Facet} from "src/upgradeability/diamond/facets/Test1Facet.sol";
import {
    IDiamondCut
} from "src/upgradeability/diamond/interfaces/IDiamondCut.sol";
import {
    IDiamondLoupe
} from "src/upgradeability/diamond/interfaces/IDiamondLoupe.sol";

import {
    DiamondInit
} from "src/upgradeability/diamond/upgradeInitializers/DiamondInit.sol";

/// @title Diamond Proxy Tests (EIP-2535)
/// @notice Tests Diamond deployment, facet management, and upgrades
contract DiamondTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    Test1Facet public test1Facet;
    DiamondInit public diamondInit;

    address public owner;
    address public alice;
    address public bob;

    // Events
    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );
    event CountIncremented(uint256 newCount);
    event CountDecremented(uint256 newCount);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy DiamondCutFacet first (required for Diamond constructor)
        diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond with owner and diamondCutFacet
        diamond = new Diamond(owner, address(diamondCutFacet));

        diamondInit = new DiamondInit();

        // Deploy other facets
        diamondLoupeFacet = new DiamondLoupeFacet();
        test1Facet = new Test1Facet();

        _registerFacets();
    }

    function _registerFacets() internal {
        // Prepare diamond cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // Add DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add Test1Facet
        bytes4[] memory test1Selectors = new bytes4[](3);
        test1Selectors[0] = test1Facet.test1Func10.selector;
        test1Selectors[1] = test1Facet.test1Func14.selector;
        test1Selectors[2] = test1Facet.getSomeValue.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(test1Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test1Selectors
        });

        // Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testFacetsRegistered() public {
        // Verify that facets are registered correctly
        IDiamondLoupe.Facet[] memory facets = IDiamondLoupe(address(diamond))
            .facets();
        assertEq(facets.length, 3, "Expected 3 facets to be registered");

        Test1Facet(address(diamond)).test1Func10();

        assertEq(
            Test1Facet(address(diamond)).getSomeValue(),
            1337,
            "Expected someValue to be 1337"
        );

        // Further assertions can be added to verify function selectors, etc.
    }

    function testDisableSomeFunction() public {
        // Remove test1Func10 from Test1Facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory selectorsToRemove = new bytes4[](1);
        selectorsToRemove[0] = test1Facet.test1Func10.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectorsToRemove
        });

        // Execute diamond cut to remove the function
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Attempting to call the removed function should revert
        vm.expectRevert();
        Test1Facet(address(diamond)).test1Func10();
    }
}
