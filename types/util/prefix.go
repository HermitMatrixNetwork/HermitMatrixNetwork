package util

import "fmt"

const (
	// Bech32PrefixAccAddr defines the Bech32 prefix of an account's address
	Bech32PrefixAccAddr = "ghm"
	// Bech32PrefixAccPub defines the Bech32 prefix of an account's public key
	Bech32PrefixAccPub = "ghmpub"
	// Bech32PrefixValAddr defines the Bech32 prefix of a validator's operator address
	Bech32PrefixValAddr = "ghmvaloper"
	// Bech32PrefixValPub defines the Bech32 prefix of a validator's operator public key
	Bech32PrefixValPub = "ghmvaloperpub"
	// Bech32PrefixConsAddr defines the Bech32 prefix of a consensus node address
	Bech32PrefixConsAddr = "ghmvalcons"
	// Bech32PrefixConsPub defines the Bech32 prefix of a consensus node public key
	Bech32PrefixConsPub = "ghmvalconspub"

	CoinType    = 928
	CoinPurpose = 44
)

var (
	// AddressVerifier secret address verifier
	AddressVerifier = func(bz []byte) error {
		if n := len(bz); n != 20 {
			return fmt.Errorf("incorrect address length %d", n)
		}

		return nil
	}
)
