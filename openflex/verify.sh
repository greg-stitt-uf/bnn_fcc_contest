openflex bnn_fcc_verify.yml > run.log 2>&1

if grep -qiE 'error:|fatal:|failure:' run.log; then
    echo "Verification FAILED (see run.log)"
elif ! grep -q 'SUCCESS:' run.log; then
    echo "Verification FAILED (see run.log)"
else
    echo "Verification PASSED"
fi