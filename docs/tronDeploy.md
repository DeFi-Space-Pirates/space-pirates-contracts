# Tron deploy

In order to deploy to the tron network some changes has to be done.

1. install tronbox with: `npm install -g tronbox`

2. Delete the function isContract that can be found at `node_modules/@openzeppelin/contracts/utils/Address.sol`

3. replace in the Address.sol occurrences of isContract(target) with target.isContract

4. replace to.isContract() with to.isContract in ERC1155Custom.sol

5. replace in libraries/SpacePiratesDexLibrary.sol the hex"ff" to hex"41"

6. run `tronbox compile` in order to create the artifacts of the contract

7. put in the file .env the TRON_PRIVATE_KEY and the TRON_FULL_HOST

8. run `npx hardhat run .\tron\deploy.js`

This repository uses the [Conventional Commits format](https://www.conventionalcommits.org/en/v1.0.0/):

- **build**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- **ci**: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
- **docs**: Documentation only changes
- **feat**: A new feature
- **fix**: A bug fix
- **perf**: A code change that improves performance
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **test**: Adding missing tests or correcting existing tests

Current development status can be consulted in the [Github Project section](https://github.com/DeFi-Space-Pirates/DeFi-Space-Pirates/projects)
