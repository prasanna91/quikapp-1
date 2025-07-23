#!/bin/bash

# iOS Ad Hoc Pre-Build Script
# Handles pre-build setup for ios-adhoc workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }


echo "🚀 Starting iOS Akash Pre-Build Setup..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version)"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
echo "  - Profile Type: $PROFILE_TYPE"

# Pre-build cleanup and optimization
echo "🧹 Pre-build cleanup..."

flutter clean > /dev/null 2>&1 || {
  log_warn "⚠️ flutter clean failed (continuing)"
}

rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

echo "Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

log_info "Setting up provisioning profile..."

CM_PROVISIONING_PROFILE="MIIwhAYJKoZIhvcNAQcCoIIwdTCCMHECAQExCzAJBgUrDgMCGgUAMIIgkQYJKoZIhvcNAQcBoIIgggSCIH48P3htbCB2ZXJzaW9uPSIxLjAiIGVuY29kaW5nPSJVVEYtOCI/Pgo8IURPQ1RZUEUgcGxpc3QgUFVCTElDICItLy9BcHBsZS8vRFREIFBMSVNUIDEuMC8vRU4iICJodHRwOi8vd3d3LmFwcGxlLmNvbS9EVERzL1Byb3BlcnR5TGlzdC0xLjAuZHRkIj4KPHBsaXN0IHZlcnNpb249IjEuMCI+CjxkaWN0PgoJPGtleT5BcHBJRE5hbWU8L2tleT4KCTxzdHJpbmc+R2FyYmNvZGU8L3N0cmluZz4KCTxrZXk+QXBwbGljYXRpb25JZGVudGlmaWVyUHJlZml4PC9rZXk+Cgk8YXJyYXk+Cgk8c3RyaW5nPjlIMkFEN05RNDk8L3N0cmluZz4KCTwvYXJyYXk+Cgk8a2V5PkNyZWF0aW9uRGF0ZTwva2V5PgoJPGRhdGU+MjAyNS0wNy0yMlQwODoxNDoxNVo8L2RhdGU+Cgk8a2V5PlBsYXRmb3JtPC9rZXk+Cgk8YXJyYXk+CgkJPHN0cmluZz5pT1M8L3N0cmluZz4KCQk8c3RyaW5nPnhyT1M8L3N0cmluZz4KCQk8c3RyaW5nPnZpc2lvbk9TPC9zdHJpbmc+Cgk8L2FycmF5PgoJPGtleT5Jc1hjb2RlTWFuYWdlZDwva2V5PgoJPGZhbHNlLz4KCTxrZXk+RGV2ZWxvcGVyQ2VydGlmaWNhdGVzPC9rZXk+Cgk8YXJyYXk+CgkJPGRhdGE+TUlJR0NUQ0NCUEdnQXdJQkFnSVFGQnRBdHFoV1JFSDhFWmJPbHZjOFZ6QU5CZ2txaGtpRzl3MEJBUXNGQURCMU1VUXdRZ1lEVlFRREREdEJjSEJzWlNCWGIzSnNaSGRwWkdVZ1JHVjJaV3h2Y0dWeUlGSmxiR0YwYVc5dWN5QkRaWEowYVdacFkyRjBhVzl1SUVGMWRHaHZjbWwwZVRFTE1Ba0dBMVVFQ3d3Q1J6TXhFekFSQmdOVkJBb01Da0Z3Y0d4bElFbHVZeTR4Q3pBSkJnTlZCQVlUQWxWVE1CNFhEVEkxTURjeU1qQTNOVGsxTkZvWERUSTJNRGN5TWpBM05UazFNMW93Z2M4eEdqQVlCZ29Ka2lhSmsvSXNaQUVCREFvNVNESkJSRGRPVVRRNU1WY3dWUVlEVlFRRERFNUJjSEJzWlNCRWFYTjBjbWxpZFhScGIyNDZJRkJwZUdGM1lYSmxJRlJsWTJodWIyeHZaM2tnVTI5c2RYUnBiMjV6SUZCeWFYWmhkR1VnVEdsdGFYUmxaQ0FvT1VneVFVUTNUbEUwT1NreEV6QVJCZ05WQkFzTUNqbElNa0ZFTjA1Uk5Ea3hOakEwQmdOVkJBb01MVkJwZUdGM1lYSmxJRlJsWTJodWIyeHZaM2tnVTI5c2RYUnBiMjV6SUZCeWFYWmhkR1VnVEdsdGFYUmxaREVMTUFrR0ExVUVCaE1DVlZNd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURGVnBiWUIzb1JTSzZwTmRNTWNBVHdaSi9aQklDc1RycUJqU2JJc3lzaWdpS21yZFhrZ1hOWWR1N2daK0w5QjFCcmMzbG54TmYzRnFON21UWUowWUNYdUdRdWVvZEprWEhhTHpUQ2MvbUhoZmljVzlYZzRnU1lGT1lLSTBuK2trRjgxbEZSdTNBY2JiWU16azJIZUk0QmxmU25WZitMd2VDQ2F4REhQbno4bEFZcmErUXp1RCs2TGN0QnkwaWJNRWEwZkJuYmRmTWsxL0hScGNZZ3pDSmtmUmVBOGUraXdKQ2UxVVlPQmgvVzgwT2IwUlE5U3hSVEQrQUE3RTIrWVBSNmdlb2h3ZXkyQlc2MUdiUFJkNFhYaFZ0YUpNS1Q3WFFqK3IxbElwcjIxVTI2WlVpNk1yQ2ltT25kOGhrazhLZExrck5ERnRWa0RwcEJRY0FUZWFtVkFnTUJBQUdqZ2dJNE1JSUNOREFNQmdOVkhSTUJBZjhFQWpBQU1COEdBMVVkSXdRWU1CYUFGQW4rd0JXUSthOWtDcElTdVNZb1l3eVg3S2V5TUhBR0NDc0dBUVVGQndFQkJHUXdZakF0QmdnckJnRUZCUWN3QW9ZaGFIUjBjRG92TDJObGNuUnpMbUZ3Y0d4bExtTnZiUzkzZDJSeVp6TXVaR1Z5TURFR0NDc0dBUVVGQnpBQmhpVm9kSFJ3T2k4dmIyTnpjQzVoY0hCc1pTNWpiMjB2YjJOemNEQXpMWGQzWkhKbk16QTFNSUlCSGdZRFZSMGdCSUlCRlRDQ0FSRXdnZ0VOQmdrcWhraUc5Mk5rQlFFd2dmOHdnY01HQ0NzR0FRVUZCd0lDTUlHMkRJR3pVbVZzYVdGdVkyVWdiMjRnZEdocGN5QmpaWEowYVdacFkyRjBaU0JpZVNCaGJua2djR0Z5ZEhrZ1lYTnpkVzFsY3lCaFkyTmxjSFJoYm1ObElHOW1JSFJvWlNCMGFHVnVJR0Z3Y0d4cFkyRmliR1VnYzNSaGJtUmhjbVFnZEdWeWJYTWdZVzVrSUdOdmJtUnBkR2x2Ym5NZ2IyWWdkWE5sTENCalpYSjBhV1pwWTJGMFpTQndiMnhwWTNrZ1lXNWtJR05sY25ScFptbGpZWFJwYjI0Z2NISmhZM1JwWTJVZ2MzUmhkR1Z0Wlc1MGN5NHdOd1lJS3dZQkJRVUhBZ0VXSzJoMGRIQnpPaTh2ZDNkM0xtRndjR3hsTG1OdmJTOWpaWEowYVdacFkyRjBaV0YxZEdodmNtbDBlUzh3RmdZRFZSMGxBUUgvQkF3d0NnWUlLd1lCQlFVSEF3TXdIUVlEVlIwT0JCWUVGQlEwL2NJeTNoZlB3c200aG15dGpVS2Ixb0xvTUE0R0ExVWREd0VCL3dRRUF3SUhnREFUQmdvcWhraUc5Mk5rQmdFSEFRSC9CQUlGQURBVEJnb3Foa2lHOTJOa0JnRUVBUUgvQkFJRkFEQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFobzRlRVB1S2dCbWhMKzl1R0xkTWJGei81K04walJGZEVwUHZVS2RXR3d4cDNzSHhOSDRYWDhkZjBsa0ZNVVV6Z1dRazUxTFVDSlIrc0pKbzU3VEZYcFdWZVU2S0I4YWNjOXVKa3diUmhUTFo4NU1mU2NoYTlNekh5MEEwMi95eWkxbXlDTGhqQm4za3k2aW5nT0dkM2g2dUtLNHVUckdqNW1IUUJlR3pHdmM3MnBNb2krblJsd1hzK211RStwR05nbEIxeVkwb1BuSmZBUnh3ZFBGaFRDQnFGRVV2WFc0ZFRUMEkyUFFYcjYrR2U0djhXN0lKbnRnVHVYbWl0OTVTRFlzcXRWQm45dndFUXZIVUR3WlRSdlNaUjRXR1lqYWRnR09vTlcyb05FQWVJU3MvZG1EZThwOG1uL1JMNm1rcldSZWsvekRIelZYSTNJZTVwRm1DYXc9PTwvZGF0YT4KCTwvYXJyYXk+CgoJPGtleT5ERVItRW5jb2RlZC1Qcm9maWxlPC9rZXk+Cgk8ZGF0YT5NSUlOYWdZSktvWklodmNOQVFjQ29JSU5XekNDRFZjQ0FRRXhEekFOQmdsZ2hrZ0JaUU1FQWdFRkFEQ0NBeVFHQ1NxR1NJYjNEUUVIQWFDQ0F4VUVnZ01STVlJRERUQU1EQWRXWlhKemFXOXVBZ0VCTUEwTUNGQlFVVU5vWldOckFRRUFNQkFNQ2xScGJXVlViMHhwZG1VQ0FnRnNNQk1NRGtseldHTnZaR1ZOWVc1aFoyVmtBUUVBTUJVTUNVRndjRWxFVG1GdFpRd0lSMkZ5WW1OdlpHVXdIUXdNUTNKbFlYUnBiMjVFWVhSbEZ3MHlOVEEzTWpJd09ERTBNVFZhTUI0TURsUmxZVzFKWkdWdWRHbG1hV1Z5TUF3TUNqbElNa0ZFTjA1Uk5Ea3dId3dPUlhod2FYSmhkR2x2YmtSaGRHVVhEVEkyTURjeU1qQTNOVGsxTTFvd0lBd1hVSEp2Wm1sc1pVUnBjM1J5YVdKMWRHbHZibFI1Y0dVTUJWTlVUMUpGTUNFTUJFNWhiV1VNR1VkaGNtSmpiMlJsWDNOcFoyNWZZWEJ3WDNCeWIyWnBiR1V3SVF3SVVHeGhkR1p2Y20wd0ZRd0RhVTlUREFSNGNrOVREQWgyYVhOcGIyNVBVekFyREJ0QmNIQnNhV05oZEdsdmJrbGtaVzUwYVdacFpYSlFjbVZtYVhnd0RBd0tPVWd5UVVRM1RsRTBPVEFzREFSVlZVbEVEQ1JpTTJJek1USmhNaTB4WW1WaExUUmpORFV0WW1WalppMHhZakJsWlRFMlpERmhabVV3T1F3SVZHVmhiVTVoYldVTUxWQnBlR0YzWVhKbElGUmxZMmh1YjJ4dloza2dVMjlzZFhScGIyNXpJRkJ5YVhaaGRHVWdUR2x0YVhSbFpEQTdEQlZFWlhabGJHOXdaWEpEWlhKMGFXWnBZMkYwWlhNd0lnUWdpbkxFdFA1YlFNQW9wVmgzYXE3VXJJYW9sL1FqV2o3RjFSd3B3bDhWb1FRd2dnRVREQXhGYm5ScGRHeGxiV1Z1ZEhOd2dnRUJBZ0VCc0lIN01EME1GbUZ3Y0d4cFkyRjBhVzl1TFdsa1pXNTBhV1pwWlhJTUl6bElNa0ZFTjA1Uk5Ea3VZMjl0TG1kaGNtSmpiMlJsTG1kaGNtSmpiMlJsWVhCd01CME1EMkZ3Y3kxbGJuWnBjbTl1YldWdWRBd0tjSEp2WkhWamRHbHZiakFZREJOaVpYUmhMWEpsY0c5eWRITXRZV04wYVhabEFRSC9NREVNSTJOdmJTNWhjSEJzWlM1a1pYWmxiRzl3WlhJdWRHVmhiUzFwWkdWdWRHbG1hV1Z5REFvNVNESkJSRGRPVVRRNU1CTU1EbWRsZEMxMFlYTnJMV0ZzYkc5M0FRRUFNRGtNRm10bGVXTm9ZV2x1TFdGalkyVnpjeTFuY205MWNITXdId3dNT1VneVFVUTNUbEUwT1M0cURBOWpiMjB1WVhCd2JHVXVkRzlyWlc2Z2dnZzhNSUlDUXpDQ0FjbWdBd0lCQWdJSUxjWDhpTkxGUzVVd0NnWUlLb1pJemowRUF3TXdaekViTUJrR0ExVUVBd3dTUVhCd2JHVWdVbTl2ZENCRFFTQXRJRWN6TVNZd0pBWURWUVFMREIxQmNIQnNaU0JEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURVRNQkVHQTFVRUNnd0tRWEJ3YkdVZ1NXNWpMakVMTUFrR0ExVUVCaE1DVlZNd0hoY05NVFF3TkRNd01UZ3hPVEEyV2hjTk16a3dORE13TVRneE9UQTJXakJuTVJzd0dRWURWUVFEREJKQmNIQnNaU0JTYjI5MElFTkJJQzBnUnpNeEpqQWtCZ05WQkFzTUhVRndjR3hsSUVObGNuUnBabWxqWVhScGIyNGdRWFYwYUc5eWFYUjVNUk13RVFZRFZRUUtEQXBCY0hCc1pTQkpibU11TVFzd0NRWURWUVFHRXdKVlV6QjJNQkFHQnlxR1NNNDlBZ0VHQlN1QkJBQWlBMklBQkpqcEx6MUFjcVR0a3lKeWdSTWMzUkNWOGNXalRuSGNGQmJaRHVXbUJTcDNaSHRmVGpqVHV4eEV0WC8xSDdZeVlsM0o2WVJiVHpCUEVWb0EvVmhZREtYMUR5eE5CMGNUZGRxWGw1ZHZNVnp0SzUxN0lEdll1VlRaWHBta09sRUtNYU5DTUVBd0hRWURWUjBPQkJZRUZMdXczcUZZTTRpYXBJcVozcjY5NjYvYXl5U3JNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEZ1lEVlIwUEFRSC9CQVFEQWdFR01Bb0dDQ3FHU000OUJBTURBMmdBTUdVQ01RQ0Q2Y0hFRmw0YVhUUVkyZTN2OUd3T0FFWkx1Tit5UmhIRkQvM21lb3locG12T3dnUFVuUFdUeG5TNGF0K3FJeFVDTUcxbWloREsxQTNVVDgyTlF6NjBpbU9sTTI3amJkb1h0MlFmeUZNbStZaGlkRGtMRjF2TFVhZ002QmdENTZLeUtEQ0NBdVl3Z2dKdG9BTUNBUUlDQ0RNTjd2aS9UR2d1TUFvR0NDcUdTTTQ5QkFNRE1HY3hHekFaQmdOVkJBTU1Fa0Z3Y0d4bElGSnZiM1FnUTBFZ0xTQkhNekVtTUNRR0ExVUVDd3dkUVhCd2JHVWdRMlZ5ZEdsbWFXTmhkR2x2YmlCQmRYUm9iM0pwZEhreEV6QVJCZ05WQkFvTUNrRndjR3hsSUVsdVl5NHhDekFKQmdOVkJBWVRBbFZUTUI0WERURTNNREl5TWpJeU1qTXlNbG9YRFRNeU1ESXhPREF3TURBd01Gb3djakVtTUNRR0ExVUVBd3dkUVhCd2JHVWdVM2x6ZEdWdElFbHVkR1ZuY21GMGFXOXVJRU5CSURReEpqQWtCZ05WQkFzTUhVRndjR3hsSUVObGNuUnBabWxqWVhScGIyNGdRWFYwYUc5eWFYUjVNUk13RVFZRFZRUUtEQXBCY0hCc1pTQkpibU11TVFzd0NRWURWUVFHRXdKVlV6QlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJBWnJwRlp2Zlo4bjBjNDJqcEliVnMxVU5tUkt5WlJvbWZySklIN2k5VmdQM09KcTZ4bEhMeTd2TzZRQnRBRVRSSHhhSnEyZ25Da2xpdVhtQm05UGZGcWpnZmN3Z2ZRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZkJnTlZIU01FR0RBV2dCUzdzTjZoV0RPSW1xU0ttZDYrdmV1djJzc2txekJHQmdnckJnRUZCUWNCQVFRNk1EZ3dOZ1lJS3dZQkJRVUhNQUdHS21oMGRIQTZMeTl2WTNOd0xtRndjR3hsTG1OdmJTOXZZM053TURNdFlYQndiR1Z5YjI5MFkyRm5NekEzQmdOVkhSOEVNREF1TUN5Z0txQW9oaVpvZEhSd09pOHZZM0pzTG1Gd2NHeGxMbU52YlM5aGNIQnNaWEp2YjNSallXY3pMbU55YkRBZEJnTlZIUTRFRmdRVWVrZTZPSW9WSkVnaVJzMitqeG9rZXpRREtta3dEZ1lEVlIwUEFRSC9CQVFEQWdFR01CQUdDaXFHU0liM1kyUUdBaEVFQWdVQU1Bb0dDQ3FHU000OUJBTURBMmNBTUdRQ01CVU1xWTdHcjVacGE2ZWYzVnpVQTFsc3JsTFVZTWFMZHVDM3hhTHhDWHpnbXVOcnNlTjhNY1FuZXFlT2lmMnJkd0l3WVRNZzhTbi8rWWN5cmluSVpEMTJlMUdrMGdJdmRyNWdJcEh4MVRwMTNMVGl4aXFXL3NZSjNFcFAxU1R3L01xeU1JSURCekNDQXEyZ0F3SUJBZ0lJRjRDb05HWms2c3N3Q2dZSUtvWkl6ajBFQXdJd2NqRW1NQ1FHQTFVRUF3d2RRWEJ3YkdVZ1UzbHpkR1Z0SUVsdWRHVm5jbUYwYVc5dUlFTkJJRFF4SmpBa0JnTlZCQXNNSFVGd2NHeGxJRU5sY25ScFptbGpZWFJwYjI0Z1FYVjBhRzl5YVhSNU1STXdFUVlEVlFRS0RBcEJjSEJzWlNCSmJtTXVNUXN3Q1FZRFZRUUdFd0pWVXpBZUZ3MHlOREV4TWpBd016SXdORFZhRncweU9ERXlNVFF4T0RBd016QmFNRTR4S2pBb0JnTlZCQU1NSVZkWFJGSWdVSEp2ZG1semFXOXVhVzVuSUZCeWIyWnBiR1VnVTJsbmJtbHVaekVUTUJFR0ExVUVDZ3dLUVhCd2JHVWdTVzVqTGpFTE1Ba0dBMVVFQmhNQ1ZWTXdXVEFUQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBVDFsRnNPd2RSVVB4bmVSbUFsWHo2T0tjOXNUNVBWSExkOXRsSmZIK0g3WXdHeWdodW9vVTYwMCszdlZya1gxSmpOWUxmT1RxbTNPbGQyVStnelE2OTlvNElCVHpDQ0FVc3dEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCUjZSN280aWhVa1NDSkd6YjZQR2lSN05BTXFhVEJCQmdnckJnRUZCUWNCQVFRMU1ETXdNUVlJS3dZQkJRVUhNQUdHSldoMGRIQTZMeTl2WTNOd0xtRndjR3hsTG1OdmJTOXZZM053TURNdFlYTnBZMkUwTURNd2daWUdBMVVkSUFTQmpqQ0JpekNCaUFZSktvWklodmRqWkFVQk1Ic3dlUVlJS3dZQkJRVUhBZ0l3YlF4clZHaHBjeUJqWlhKMGFXWnBZMkYwWlNCcGN5QjBieUJpWlNCMWMyVmtJR1Y0WTJ4MWMybDJaV3g1SUdadmNpQm1kVzVqZEdsdmJuTWdhVzUwWlhKdVlXd2dkRzhnUVhCd2JHVWdVSEp2WkhWamRITWdZVzVrTDI5eUlFRndjR3hsSUhCeWIyTmxjM05sY3k0d0hRWURWUjBPQkJZRUZPbFN6ZzJ3eG9nYVpVcTRteEdQOGR3ZVJ4UjhNQTRHQTFVZER3RUIvd1FFQXdJSGdEQVBCZ2txaGtpRzkyTmtEQk1FQWdVQU1Bb0dDQ3FHU000OUJBTUNBMGdBTUVVQ0lRRHZtcnhkb0ZwbWJHUzV6VGVUcVZPME44WEhiT0dEK2hjYTNnczkxcXRvWmdJZ2VDUFp3NGdIU1QzMSs0bVBrRzVZNEZlZlkvOVk0ZGFQWEpoajFqbytQNTB4Z2dIWE1JSUIwd0lCQVRCK01ISXhKakFrQmdOVkJBTU1IVUZ3Y0d4bElGTjVjM1JsYlNCSmJuUmxaM0poZEdsdmJpQkRRU0EwTVNZd0pBWURWUVFMREIxQmNIQnNaU0JEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURVRNQkVHQTFVRUNnd0tRWEJ3YkdVZ1NXNWpMakVMTUFrR0ExVUVCaE1DVlZNQ0NCZUFxRFJtWk9yTE1BMEdDV0NHU0FGbEF3UUNBUVVBb0lIcE1CZ0dDU3FHU0liM0RRRUpBekVMQmdrcWhraUc5dzBCQndFd0hBWUpLb1pJaHZjTkFRa0ZNUThYRFRJMU1EY3lNakE0TVRReE5Wb3dLZ1lKS29aSWh2Y05BUWswTVIwd0d6QU5CZ2xnaGtnQlpRTUVBZ0VGQUtFS0JnZ3Foa2pPUFFRREFqQXZCZ2txaGtpRzl3MEJDUVF4SWdRZ3VFR3pYT3hhOHJ5RTFEdTRVMkJHSWxYV2RGeVdxanhENWRSUkNmcDRWbXd3VWdZSktvWklodmNOQVFrUE1VVXdRekFLQmdncWhraUc5dzBEQnpBT0JnZ3Foa2lHOXcwREFnSUNBSUF3RFFZSUtvWklodmNOQXdJQ0FVQXdCd1lGS3c0REFnY3dEUVlJS29aSWh2Y05Bd0lDQVNnd0NnWUlLb1pJemowRUF3SUVSekJGQWlCcHlLOVZkNGtFK1dHRWIzeC9NeWVxNkpzYzBTNG84Z0ZmRTBJL3haWTU2Z0loQU10QkxwVFl4dXNwSHpLYzdYMENIZHZ2UlRZN0ZyVE1sa3YxNUdNcURtTnQ8L2RhdGE+CgkJCQkJCQkJCQkJCQkJCgkJCTxrZXk+UFBRQ2hlY2s8L2tleT4KCTxmYWxzZS8+CgoJPGtleT5FbnRpdGxlbWVudHM8L2tleT4KCTxkaWN0PgoJCTxrZXk+YmV0YS1yZXBvcnRzLWFjdGl2ZTwva2V5PgoJCTx0cnVlLz4KCQkJCQoJCQkJPGtleT5hcHMtZW52aXJvbm1lbnQ8L2tleT4KCQk8c3RyaW5nPnByb2R1Y3Rpb248L3N0cmluZz4KCQkJCQoJCQkJPGtleT5hcHBsaWNhdGlvbi1pZGVudGlmaWVyPC9rZXk+CgkJPHN0cmluZz45SDJBRDdOUTQ5LmNvbS5nYXJiY29kZS5nYXJiY29kZWFwcDwvc3RyaW5nPgoJCQkJCgkJCQk8a2V5PmtleWNoYWluLWFjY2Vzcy1ncm91cHM8L2tleT4KCQk8YXJyYXk+CgkJCQk8c3RyaW5nPjlIMkFEN05RNDkuKjwvc3RyaW5nPgoJCQkJPHN0cmluZz5jb20uYXBwbGUudG9rZW48L3N0cmluZz4KCQk8L2FycmF5PgoJCQkJCgkJCQk8a2V5PmdldC10YXNrLWFsbG93PC9rZXk+CgkJPGZhbHNlLz4KCQkJCQoJCQkJPGtleT5jb20uYXBwbGUuZGV2ZWxvcGVyLnRlYW0taWRlbnRpZmllcjwva2V5PgoJCTxzdHJpbmc+OUgyQUQ3TlE0OTwvc3RyaW5nPgoJCQoJPC9kaWN0PgoJPGtleT5FeHBpcmF0aW9uRGF0ZTwva2V5PgoJPGRhdGU+MjAyNi0wNy0yMlQwNzo1OTo1M1o8L2RhdGU+Cgk8a2V5Pk5hbWU8L2tleT4KCTxzdHJpbmc+R2FyYmNvZGVfc2lnbl9hcHBfcHJvZmlsZTwvc3RyaW5nPgoJPGtleT5UZWFtSWRlbnRpZmllcjwva2V5PgoJPGFycmF5PgoJCTxzdHJpbmc+OUgyQUQ3TlE0OTwvc3RyaW5nPgoJPC9hcnJheT4KCTxrZXk+VGVhbU5hbWU8L2tleT4KCTxzdHJpbmc+UGl4YXdhcmUgVGVjaG5vbG9neSBTb2x1dGlvbnMgUHJpdmF0ZSBMaW1pdGVkPC9zdHJpbmc+Cgk8a2V5PlRpbWVUb0xpdmU8L2tleT4KCTxpbnRlZ2VyPjM2NDwvaW50ZWdlcj4KCTxrZXk+VVVJRDwva2V5PgoJPHN0cmluZz5iM2IzMTJhMi0xYmVhLTRjNDUtYmVjZi0xYjBlZTE2ZDFhZmU8L3N0cmluZz4KCTxrZXk+VmVyc2lvbjwva2V5PgoJPGludGVnZXI+MTwvaW50ZWdlcj4KPC9kaWN0Pgo8L3BsaXN0PqCCDT8wggQ0MIIDHKADAgECAgg9Wfg36tHYnzANBgkqhkiG9w0BAQsFADBzMS0wKwYDVQQDDCRBcHBsZSBpUGhvbmUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxIDAeBgNVBAsMF0NlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzAeFw0yNDEyMTYxOTIxMDFaFw0yOTEyMTExODEzNTlaMFkxNTAzBgNVBAMMLEFwcGxlIGlQaG9uZSBPUyBQcm92aXNpb25pbmcgUHJvZmlsZSBTaWduaW5nMRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANCTMav4Ux7frR4vZPfJTdeWvl9LPXlkXEPuKcNA0vovHKC2vBFz7/AisN/e+fnOVeP1QgG1I2VBEjv3fEZ9iRNFlUTslpViZpeQAwDZ4K7F2bGcIC2W4IXtb2vTUtODPNQBIyXp5cbUEdh5qgjC3RVY9e+Kk0sNS+4NtoeTdREQVcsMeAfbN3BGO5f6xOt4KeD07HjjYdpAV4AHu4icpcdJbcgm05UfTSGijWhzgx7mWVqFllVUsJUuJdx3DWGHgY2JpAN7PAB3LIlqWdNkRNl0pVuKsVJhX24EMNTz4hA0DJWMS+F71iuFg/InOY1wCCPiFIj/k/QtbUwm4os3hi0CAwEAAaOB5TCB4jAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFG/xlRhiXODI8cXtbBjJ4NNkUpggMEAGCCsGAQUFBwEBBDQwMjAwBggrBgEFBQcwAYYkaHR0cDovL29jc3AuYXBwbGUuY29tL29jc3AwMy1haXBjYTA3MC8GA1UdHwQoMCYwJKAioCCGHmh0dHA6Ly9jcmwuYXBwbGUuY29tL2FpcGNhLmNybDAdBgNVHQ4EFgQUvLXF6b38y9Ce3JSwHvghlFz/CS4wDgYDVR0PAQH/BAQDAgeAMA8GCSqGSIb3Y2QGOgQCBQAwDQYJKoZIhvcNAQELBQADggEBADI0wul3ql/gxsqi83dZ54pnuPFR8/uw9pe/sRGj4aE8uyOS6RKTonEdvPGacW+kPG82krbgR4Kik+PnuI+73yVEYgLPzbz3+42KCXB4ZcIZTSXLcmIh5Klo+RCaLnoPKL6mAwbRVWEfr3z4lNRxDuLTJVSLzq3VaAdbvS17x2JFebmph0z4GDuArhBLcdh4K+YKr5rn2U3M6lu3o5dVa+wNoHjHwLDPy9wQTDCSE3GU1q/g7MnpyZvOJTLuEQ0hFySL8ZUuImJGRX/g29cWVMG5PtPairll9rS0I394XdlydmRjpwhVx9m3lNsjv/OTp9QEREMNyuJWsiuUKKQ9cocwggREMIIDLKADAgECAghcY8rkSjdTyTANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMTcwNTEwMjEyNzMwWhcNMzAxMjMxMDAwMDAwWjBzMS0wKwYDVQQDDCRBcHBsZSBpUGhvbmUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxIDAeBgNVBAsMF0NlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMlFagEPPoMEhsf8v9xe8B6B7hcwc2MmLt49eiTNkz5POUe6db7zwNLxWaKrH/4KhjzZLZoH8g5ruSmRGl8iCovxclgFrkxLRMV5p4A8sIjgjAwnhF0Z5YcZNsvjxXa3sPRBclH0BVyDS6JtplG48Sbfe16tZQzGsphRjLt9G0zBTsgIx9LtZAu03RuNT0B9G49IlpJb89CYftm8pBkOmWG7QV0BzFt3en0k0NzTU//D3MWULLZaTY4YIzm92cZSPtHy9CWKoSqH/dgMRilR/+0XbIkla4e/imkUn3efwxW3aLOIRb2E5gYCQWQPrSoouBXJ4KynirpyBDSyeIz4soUCAwEAAaOB7DCB6TAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFCvQaUeUdgn+9GuNLkCm90dNfwheMEQGCCsGAQUFBwEBBDgwNjA0BggrBgEFBQcwAYYoaHR0cDovL29jc3AuYXBwbGUuY29tL29jc3AwMy1hcHBsZXJvb3RjYTAuBgNVHR8EJzAlMCOgIaAfhh1odHRwOi8vY3JsLmFwcGxlLmNvbS9yb290LmNybDAdBgNVHQ4EFgQUb/GVGGJc4Mjxxe1sGMng02RSmCAwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAhIEAgUAMA0GCSqGSIb3DQEBCwUAA4IBAQA6z6yYjb6SICEJrZXzsVwh+jYtVyBEdHNkkgizlqz3bZf6WzQ4J88SRtM8EfAHyZmQsdHoEQml46VrbGMIP54l+tWZnEzm5c6Osk1o7Iuro6JPihEVPtwUKxzGRLZvZ8VbT5UpLYdcP9yDHndP7dpUpy3nE4HBY8RUCxtLCmooIgjUN5J8f2coX689P7esWR04NGRa7jNKGUJEKcTKGGvhwVMtLfRNwhX2MzIYePEmb4pN65RMo+j/D7MDi2Xa6y7YZVCf3J+K3zGohFTcUlJB0rITHTFGR4hfPu7D8owjBJXrrIo+gmwGny7ji0OaYls0DfSZzyzuunKGGSOl/I61MIIEuzCCA6OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDYwNDI1MjE0MDM2WhcNMzUwMjA5MjE0MDM2WjBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDkkakJH5HbHkdQ6wXtXnmELes2oldMVeyLGYne+Uts9QerIjAC6Bg++FAJ039BqJj50cpmnCRrEdCju+QbKsMflZ56DKRHi1vUFjczy8QPTc4UadHJGXL1XQ7Vf1+b8iUDulWPTV0N8WQ1IxVLFVkds5T39pyez1C6wVhQZ48ItCD3y6wsIG9wtj8BMIy3Q88PnT3zK0koGsj+zrW5DtleHNbLPbU6rfQPDgCSC7EhFi501TwN22IWq6NxkkdTVcGvL0Gz+PvjcM3mo0xFfh9Ma1CWQYnEdGILEINBhzOKgbEwWOxaBDKMaLOPHd5lc/9nXmW8Sdh2nzMUZaF3lMktAgMBAAGjggF6MIIBdjAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUK9BpR5R2Cf70a40uQKb3R01/CF4wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wggERBgNVHSAEggEIMIIBBDCCAQAGCSqGSIb3Y2QFATCB8jAqBggrBgEFBQcCARYeaHR0cHM6Ly93d3cuYXBwbGUuY29tL2FwcGxlY2EvMIHDBggrBgEFBQcCAjCBthqBs1JlbGlhbmNlIG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBjb25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZpY2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMA0GCSqGSIb3DQEBBQUAA4IBAQBcNplMLXi37Yyb3PN3m/J20ncwT8EfhYOFG5k9RzfyqZtAjizUsZAS2L70c5vu0mQPy3lPNNiiPvl4/2vIB+x9OYOLUyDTOMSxv5pPCmv/K/xZpwUJfBdAVhEedNO3iyM7R6PVbyTi69G3cN8PReEnyvFteO3ntRcXqNx+IjXKJdXZD9Zr1KIkIxH3oayPc4FgxhtbCS+SsvhESPBgOJ4V9T0mZyCKM2r3DYLP3uujL/lTaltkwGMzd/c6ByxW69oPIQ7aunMZT7XZNn/Bh1XZp5m5MkL72NVxnn6hUrcbvZNCJBIqxw8dtk2cXmPIS4AXUKqK1drk/NAJBzewdXUhMYIChTCCAoECAQEwfzBzMS0wKwYDVQQDDCRBcHBsZSBpUGhvbmUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxIDAeBgNVBAsMF0NlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUwIIPVn4N+rR2J8wCQYFKw4DAhoFAKCB3DAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA3MjIwODE0MTVaMCMGCSqGSIb3DQEJBDEWBBQO8OuBL6bzpWu9nHGCDmDG09gnOjApBgkqhkiG9w0BCTQxHDAaMAkGBSsOAwIaBQChDQYJKoZIhvcNAQEBBQAwUgYJKoZIhvcNAQkPMUUwQzAKBggqhkiG9w0DBzAOBggqhkiG9w0DAgICAIAwDQYIKoZIhvcNAwICAUAwBwYFKw4DAgcwDQYIKoZIhvcNAwICASgwDQYJKoZIhvcNAQEBBQAEggEAUphXJw6FAVk1JZOj8yDspuNVWNCJPXfXKjsraNc625k+UIisngS7gvDVvR94Is6qDCKY418DeiP1/jJgAcTEw+3pkHAOq5IRNPYanHWVmsuMMS2Fud/svpANLlG9xWgUDAnmVK6wkXKdSsmlCmzoOdo/fSMf25Xof4JGSJfKDAH2VnbDPfHlQXtLDdb847X6oS7EeGkOwi0M6SoF86ANS2yBwZ5pCeU/BUKOPQh6YyfynqE4kan9LxRDWUm8N6cPhcsSLlOGs7Hd5xphP/KfOOalQbY7osBvnFN1PLvk6vxVgGHBU7WoOkuUOjXloHBHA09EbBulVzY5XJkArocS6w=="
      PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
      mkdir -p "$PROFILES_HOME"
      PROFILE_PATH="$(mktemp "$PROFILES_HOME"/$(uuidgen).mobileprovision)"
      echo ${CM_PROVISIONING_PROFILE} | base64 --decode > "$PROFILE_PATH"
      echo "Saved provisioning profile $PROFILE_PATH"

# Extract the embedded plist from the provisioning profile
security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist

# Extract UUID
UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist)
# Extract Bundle Identifier (assuming it's the first in the Entitlements dictionary)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist | cut -d '.' -f 2-)

if [[ -z "$UUID" ]]; then
  echo "❌ Missing required variable: UUID"
  exit 1
fi

if [[ -z "$BUNDLE_ID" ]]; then
  echo "❌ Missing required variable: BUNDLE_ID"
  exit 1
fi

echo "UUID: $UUID"
echo "Bundle Identifier: $BUNDLE_ID"

CM_CERTIFICATE="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"
CM_CERTIFICATE_PASSWORD="Q77xFcYv"
echo $CM_CERTIFICATE | base64 --decode > /tmp/certificate.p12
keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password $CM_CERTIFICATE_PASSWORD

echo "Set up code signing settings on Xcode project"
xcode-project use-profiles

# Validate that a valid Apple Distribution identity is available in the keychain
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c 'Apple Distribution')
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
  echo "❌ No valid Apple Distribution signing identities found in keychain. Exiting build."
  exit 1
else
  echo "✅ Found $IDENTITY_COUNT valid Apple Distribution identity(ies) in keychain."
fi

# Function to run CocoaPods commands
run_cocoapods_commands() {

  # Backup and remove Podfile.lock if it exists
  if [ -f "ios/Podfile.lock" ]; then
    cp ios/Podfile.lock ios/Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
    rm ios/Podfile.lock
    log_info "🗑️ Removed original Podfile.lock"
  else
    log_warn "⚠️ Podfile.lock not found — skipping backup and removal"
  fi

    log_info "📦 Running CocoaPods commands..."

    if ! command -v pod &>/dev/null; then
        log_error "CocoaPods is not installed!"
        exit 1
    fi

    pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }

    log_info "🔄 Running: pod install"
    if pod install > /dev/null 2>&1; then
        log_success "✅ pod install completed successfully"
    else
        log_error "❌ pod install failed"
        popd > /dev/null
        return 1
    fi

    if [ "${RUN_POD_UPDATE:-false}" = "true" ]; then
        log_info "🔄 Running: pod update"
        if ! pod update > /dev/null 2>&1; then
            log_warn "⚠️ pod update had issues (continuing)"
        fi
    fi

    popd > /dev/null

    log_success "✅ CocoaPods commands completed"
}

# Function to echo bundle identifiers for all frameworks and target
echo_bundle_identifiers() {
    log_info "📱 Echoing bundle identifiers for all frameworks and target..."

    echo ""
    echo "🎯 BUNDLE IDENTIFIERS REPORT"
    echo "================================================================="

    # Main app bundle ID
    if [ -f "ios/Runner/Info.plist" ]; then
        main_bundle_id=$(plutil -extract CFBundleIdentifier raw "ios/Runner/Info.plist" 2>/dev/null || echo "NOT_FOUND")
        echo "📱 Main App Bundle ID: $main_bundle_id"
    else
        echo "❌ Main app Info.plist not found"
    fi

    # Xcode project
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        echo ""
        echo "🏗️ Xcode Project Bundle Identifiers:"
        grep -o "PRODUCT_BUNDLE_IDENTIFIER = [^;]*;" "ios/Runner.xcodeproj/project.pbxproj"
    else
        echo "❌ Xcode project file not found"
    fi

    # CocoaPods Info.plists
    if [ -d "ios/Pods" ]; then
        echo ""
        echo "📦 CocoaPods Framework Bundle Identifiers:"
        find "ios/Pods" -name "Info.plist" | while read -r plist; do
            framework_name=$(echo "$plist" | sed 's|.*Pods/\([^/]*\).*|\1|')
            bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || echo "NOT_FOUND")
            echo "   📦 $framework_name: $bundle_id"
        done
    else
        echo "ℹ️ CocoaPods directory not found"
    fi

    echo ""
    echo "================================================================="
    log_success "✅ Bundle identifiers report completed"
}

echo "📝 Generating environment configuration for Dart..."
chmod +x lib/scripts/ios-akash/gen_env_config.sh
if ./lib/scripts/ios-akash/gen_env_config.sh; then
  echo "✅ Environment configuration generated successfully"
else
  echo "❌ Environment configuration generation failed, continuing anyway"
fi

    # Download branding assets (logo, splash, splash background)
    echo "🎨 Downloading branding assets..."
    if [ -f "lib/scripts/ios-akash/branding.sh" ]; then
      chmod +x lib/scripts/ios-akash/branding.sh
      if ./lib/scripts/ios-akash/branding.sh; then
        echo "✅ Branding assets download completed"
      else
        echo "❌ Branding assets download failed"
        exit 1
      fi
    else
      echo "⚠️ Branding script not found, skipping branding assets download"
    fi

    # Download custom icons for bottom menu (if enabled)
    echo "🎨 Downloading custom icons for bottom menu..."
    if [ "${IS_BOTTOMMENU:-false}" = "true" ]; then
      if [ -f "lib/scripts/ios-akash/download_custom_icons.sh" ]; then
        chmod +x lib/scripts/ios-akash/download_custom_icons.sh
        if ./lib/scripts/ios-akash/download_custom_icons.sh; then
          echo "✅ Custom icons download completed"

          # Validate custom icons if BOTTOMMENU_ITEMS contains custom icons
          if [ -n "${BOTTOMMENU_ITEMS:-}" ]; then
            echo "🔍 Validating custom icons..."
            if [ -d "assets/icons" ] && [ "$(ls -A assets/icons 2>/dev/null)" ]; then
              echo "✅ Custom icons found in assets/icons/"
              ls -la assets/icons/ | while read -r line; do
                echo "   $line"
              done
            else
              echo "ℹ️ No custom icons found (using preset icons only)"
            fi
          fi
        else
          echo "❌ Custom icons download failed"
          exit 1
        fi
      else
        echo "⚠️ Custom icons download script not found, skipping..."
      fi
    else
      echo "ℹ️ Bottom menu disabled (IS_BOTTOMMENU=false), skipping custom icons download"
    fi

    echo "✅ Pre-build setup completed successfully"

# Dynamic Info.plist injection from environment variables
echo "📱 Injecting Info.plist values from environment variables..."
chmod +x lib/scripts/ios-akash/inject_info_plist.sh
if ./lib/scripts/ios-akash/inject_info_plist.sh; then
  echo "✅ Info.plist injection completed"
else
  echo "❌ Info.plist injection failed"
  exit 1
fi

    # Make conditional Firebase injection script executable
    chmod +x lib/scripts/ios-akash/conditional_firebase_injection.sh

    # Run conditional Firebase injection based on PUSH_NOTIFY flag
    if ! ./lib/scripts/ios-akash/conditional_firebase_injection.sh; then
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Conditional Firebase injection failed."
        return 1
    fi

log_info "Building Flutter iOS app..."

    # Determine build configuration based on profile type
   build_mode="release"
   build_config="Release"

    case "${PROFILE_TYPE:-app-store}" in
        "development")
            build_mode="debug"
            build_config="Debug"
            ;;
        "ad-hoc"|"enterprise"|"app-store")
            build_mode="release"
            build_config="Release"
            ;;
    esac

    log_info "Building in $build_mode mode for $PROFILE_TYPE distribution"

# Install Flutter dependencies (including rename package)
echo "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
  log_error "flutter pub get failed"
  exit 1
}

    run_cocoapods_commands

    #echo_bundle_identifiers

# Determine build mode and config
case "$PROFILE_TYPE" in
  development)
    build_mode="debug"
    build_config="Debug"
    ;;
  ad-hoc|enterprise|app-store)
    build_mode="release"
    build_config="Release"
    ;;
  *)
    log_warn "Unknown PROFILE_TYPE '$PROFILE_TYPE', defaulting to release"
    build_mode="release"
    build_config="Release"
    ;;
esac

xcodebuild -workspace ios/Runner.xcworkspace -list

xcodebuild -list -workspace ios/Runner.xcworkspace


# Set provisioning profile only for Runner target and build configs

# Replace or add provisioning profile for Runner target (assuming target name "Runner")

sed -i '' -E '
  /Begin PBXNativeTarget section/,/End PBXNativeTarget section/ {
    /name = Runner;/, /};/ {
      s/PROVISIONING_PROFILE_SPECIFIER = [^;]+;/PROVISIONING_PROFILE_SPECIFIER = "'"$UUID"'";/g
      s/CODE_SIGN_IDENTITY = [^;]+;/CODE_SIGN_IDENTITY = "Apple Distribution";/g
    }
  }
' ios/Runner.xcodeproj/project.pbxproj

# Remove provisioning profiles from Pods targets
#sed -i '' -E '
#  /Begin PBXNativeTarget section/,/End PBXNativeTarget section/ {
#    /name = FirebaseMessaging;/, /};/ {
#      s/PROVISIONING_PROFILE_SPECIFIER = [^;]+;//g
#      s/CODE_SIGN_IDENTITY = [^;]+;//g
#    }
#  }
#' ios/Runner.xcodeproj/project.pbxproj

# Backup the current project before build
zip -r project_backup.zip . -x "build/*" ".dart_tool/*" ".git/*" "output/*"


#temporary set to release permanenlty
log_info "📱 Building Flutter iOS app in $build_mode mode..."
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" \
  --build-number="$VERSION_CODE" \
  2>&1 | tee flutter_build.log | grep -E "(Building|Error|FAILURE|warning|Warning|error|Exception|\.dart)"

log_info "📦 Archiving app with Xcode..."
mkdir -p build/ios/archive

#xcodebuild -showBuildSettings -scheme Runner -configuration Release

echo "Current directory: $(pwd)"
ls -l ios/Runner.xcworkspace

xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  archive \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  2>&1 | tee xcodebuild_archive.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

log_info "🛠️ Writing ExportOptions.plist..."
cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>provisioningProfiles</key>
    <dict>
      <key>$BUNDLE_ID</key>
      <string>$UUID</string>
    </dict>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
EOF

log_info "📤 Exporting IPA..."
OUTPUT_DIR="${OUTPUT_DIR:-build/ios/output}"
mkdir -p "$OUTPUT_DIR"
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath "$OUTPUT_DIR" \
  -exportOptionsPlist ios/ExportOptions.plist \
  2>&1 | tee xcodebuild_export.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

IPA_PATH=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -n 1)

if [ -f "$IPA_PATH" ]; then
  mv "$IPA_PATH" "$OUTPUT_DIR/$APP_NAME.ipa"
  log_success "✅ IPA created: $OUTPUT_DIR/$APP_NAME.ipa"
else
  log_error "❌ IPA file not found. Build may have failed."
  exit 1
fi


log_success "🎉 iOS build process completed successfully!"
