syntax case match

syntax match xMissingSection /-- [a-zA-Z ]\+/
highlight link xMissingSection Comment

syntax match xSectionTitle /###[ A-Z]\+/
highlight link xSectionTitle SpellBad

syntax match xFileNumer /\[\d\+\]/
highlight link xFileNumer Special
