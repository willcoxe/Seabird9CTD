# Remove stupid characters
export remCharDf, remCharStr

```
Run each column name through the string fixer to remove invalid characters
```
function remCharDf(q)

    i = 1
    for qq in names(q)
      q   = rename!(q, names(q)[i] => remCharStr(qq))
      i+=1
    end
    return(q)
end

```
Remove invalid characters from string
```
function remCharStr(r)

    w = []              # empty array
    v = split(r, "")    # split the string into individual characters

    for vvv in v
        if vvv != "\xe9"  # remove \xe9 escape character if ut exists
          push!(w,vvv)    # push to empty directory
        end
      r =  join(w,"")     # join the string back together again
    end

    r = replace(r, r"#DIV/0!"=> "") # replace excel string #DIV/0!
    r = replace(r, r"\-"=>"")   # replace character '-'
    r = replace(r, r"\/"=>"")   # replace character '/'
    return(r)
end
