.sub _ :load :init :anon

.end

.sub compile
    .param string code
    $P0 = compreg "perl6"
    $P0(code)
.end
