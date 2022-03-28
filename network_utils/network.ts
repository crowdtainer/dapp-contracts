import 'dotenv/config';
export function node_url_for(network: string): string {
  if (network) {
    const uri = process.env['ETH_NODE_URI_' + network.toUpperCase()];
    if (uri && uri !== '') {
      return uri;
    }
  }

  if (network === 'localhost') {
    // do not use ETH_NODE_URI
    return 'http://localhost:8545';
  }

  let uri = process.env.ETH_NODE_URI;
  if (uri) {
    uri = uri.replace('{{networkName}}', network);
  }
  if (!uri || uri === '') {
    throw new Error(`environment variable "ETH_NODE_URI" not configured `);
  }
  if (uri.indexOf('{{') >= 0) {
    throw new Error(
      `invalid uri or network not supported by node provider : ${uri}`
    );
  }
  return uri;
}

function getMnemonic(network?: string): string {
  if (network) {
    const mnemonic = process.env['MNEMONIC_' + network.toUpperCase()];
    if (mnemonic && mnemonic !== '') {
      return mnemonic;
    }
  }

  const mnemonic = process.env.MNEMONIC;
  if (!mnemonic || mnemonic === '') {
    throw new Error(`No valid mnemonic found for network ${network}`);
  }
  return mnemonic;
}

export function mnemonicAccountsFor(network?: string): {mnemonic: string} {
  return {mnemonic: getMnemonic(network)};
}

export function privateKeysFor(network: string): string[] {
    let environmentVarName = 'PRIVATE_KEY_' + network.toUpperCase();
    const privateKey = process.env[environmentVarName];
    if (!privateKey || privateKey === '') {
        throw new Error(`environment variable ${environmentVarName} not set. `);
    }
    return privateKey.split(",");
  }