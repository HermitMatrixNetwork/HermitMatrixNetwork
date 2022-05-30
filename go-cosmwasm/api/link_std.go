//go:build !ghmcli && linux && !muslc && !darwin
// +build !ghmcli,linux,!muslc,!darwin

package api

// #cgo LDFLAGS: -Wl,-rpath,${SRCDIR} -L${SRCDIR} -lgo_cosmwasm
import "C"
