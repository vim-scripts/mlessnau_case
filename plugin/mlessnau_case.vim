let s:error = -1
let s:success = 0
let s:usc = 1
let s:lsc = 2
let s:ucc = 3
let s:lcc = 4

function! IdentifyCase(word)
  let l:usc_pattern = '^[A-Z0-9_]\+$'
  let l:lsc_pattern = '^[a-z0-9_]\+$'
  let l:ucc_pattern = '^\(_*[A-Z][a-z0-9]\+\)\+_*$'
  let l:lcc_pattern = '^_*[a-z][a-z0-9]\+\(_*[A-Z][a-z0-9]\+\)*_*$'

  if !empty(matchstr(a:word, l:usc_pattern))
    return s:usc
  elseif !empty(matchstr(a:word, l:lsc_pattern))
    return s:lsc
  elseif !empty(matchstr(a:word, l:ucc_pattern))
    return s:ucc
  elseif !empty(matchstr(a:word, l:lcc_pattern))
    return s:lcc
  endif

  return s:error
endfunction

function! ReadCharUnderCursor()
  let l:col = col('.')
  let l:line = line('.')

  execute 'normal! v"cy'
  let l:char = @c

  call cursor(l:line, l:col)

  return l:char
endfunction

function! ReadWordUnderCursor()
  let l:col = col('.')
  let l:line = line('.')

  execute 'normal! "cyiw'
  let l:word = @c
  call cursor(l:line, l:col)

  return l:word
endfunction

function! GetColMax(line)
  let l:col = col('.')
  let l:line = line('.')

  call cursor(a:line, 1)

  execute 'normal! $'
  let l:colMax = col('.')

  call cursor(l:line, l:col)

  return l:colMax
endfunction

function! GetCamelCaseSegmentColStart(col, line)
  let l:col = col('.')
  let l:line = line('.')
  let l:colStart = a:col

  while 1
    call cursor(a:line, l:colStart)
    let l:char = ReadCharUnderCursor()

    if !empty(matchstr(l:char, '^[A-Z]$'))
      break
    elseif !empty(matchstr(l:char, '^[a-z0-9]$'))
      let l:colStart = l:colStart - 1

      if l:colStart < 1
        let l:colStart = 1
        break
      endif
    else
      let l:colStart = l:colStart + 1
      break
    endif
  endwhile

  call cursor(l:line, l:col)

  return l:colStart
endfunction

function! GetCamelCaseSegmentColEnd(col, line)
  let l:colMax = GetColMax(a:line)

  if a:col >= l:colMax
    return l:colMax
  endif

  let l:col = col('.')
  let l:line = line('.')
  let l:colEnd = a:col + 1

  while 1 == 1
    call cursor(a:line, l:colEnd)
    let l:char = ReadCharUnderCursor()

    if !empty(matchstr(l:char, '^[A-Z]$'))
      let l:colEnd = l:colEnd - 1
      break
    elseif !empty(matchstr(l:char, '^[a-z0-9]$'))
      let l:colEnd = l:colEnd + 1

      if l:colEnd > l:colMax
        let l:colEnd = l:colMax
        break
      endif
    else
      let l:colEnd = l:colEnd - 1
      break
    endif
  endwhile

  call cursor(l:line, l:col)

  return l:colEnd
endfunction

function! SelectInCamelCase()
  let l:col = col('.')
  let l:line = line('.')

  if empty(matchstr(ReadCharUnderCursor(), '^[A-Za-z0-9]$'))
    return s:error
  endif

  let l:colStart = GetCamelCaseSegmentColStart(l:col, l:line)
  let l:colEnd = GetCamelCaseSegmentColEnd(l:col, l:line)
  let l:length = l:colEnd - l:colStart

  call cursor(l:line, l:colStart)
  execute 'normal! v' . l:length . 'l'

  return s:success
endfunction

function! SelectInSnakeCase()
  if empty(matchstr(ReadCharUnderCursor(), '^[A-Za-z0-9]$'))
    return s:error
  endif

  set iskeyword-=_
  execute 'normal! viw'
  set iskeyword+=_

  return s:success
endfunction

function! SelectInCase()
  let l:word = ReadWordUnderCursor()
  let l:case = IdentifyCase(l:word)

  if l:case == s:ucc
    return SelectInCamelCase()
  elseif l:case == s:lcc
    return SelectInCamelCase()
  elseif l:case == s:usc
    return SelectInSnakeCase()
  elseif l:case == s:lsc
    return SelectInSnakeCase()
  endif

  return s:error
endfunction

function! DeleteInCase()
  if SelectInCase() == s:success
    execute 'normal! d'
  endif
endfunction

function! ChangeInCase()
  if SelectInCase() == s:success
    execute 'normal! x'

    let l:col = col('.')
    let l:line = line('.')
    let l:colMax = GetColMax(l:line)

    startinsert

    if l:col == l:colMax
      call cursor(l:line, l:col + 1)
    endif
  endif
endfunction

map vic :call SelectInCase()<CR>
map dic :call DeleteInCase()<CR>
map cic :call ChangeInCase()<CR>
