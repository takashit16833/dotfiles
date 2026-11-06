-- Google Chrome のタブをドメイン単位で検索し、見つけたタブを前面に出す。
-- 引数はドメイン名のみ。見つからない場合はブラウザを起動しない。
on run arguments
    if (count of arguments) is not 1 then error "Expected a domain argument"
    set targetDomain to item 1 of arguments

    if application "Google Chrome" is not running then return "NOT_FOUND"

    tell application "Google Chrome"
        repeat with windowPosition from 1 to (count of windows)
            set browserWindow to window windowPosition
            set browserWindowId to id of browserWindow
            repeat with tabPosition from 1 to (count of tabs of browserWindow)
                set currentURL to ""
                try
                    set currentURL to URL of tab tabPosition of browserWindow
                end try

                if my belongsToDomain(currentURL, targetDomain) then
                    set active tab index of window id browserWindowId to tabPosition
                    set index of window id browserWindowId to 1
                    activate
                    return "FOUND"
                end if
            end repeat
        end repeat
    end tell

    return "NOT_FOUND"
end run

on belongsToDomain(pageURL, targetDomain)
    if pageURL is missing value then return false
    set address to pageURL as text

    if address starts with "https://" then
        if (length of address) is less than or equal to 8 then return false
        set hostname to text 9 thru -1 of address
    else if address starts with "http://" then
        if (length of address) is less than or equal to 7 then return false
        set hostname to text 8 thru -1 of address
    else
        return false
    end if

    -- パス、検索条件、フラグメント、ポート番号を除いてホスト名だけを比較する。
    repeat with separator in {"/", "?", "#", ":"}
        set separatorPosition to offset of (separator as text) in hostname
        if separatorPosition is 1 then return false
        if separatorPosition > 1 then set hostname to text 1 thru (separatorPosition - 1) of hostname
    end repeat

    -- youtube.com / www.youtube.com 等を許可し、youtube.com.evil.example は除外する。
    if hostname is targetDomain then return true
    if hostname ends with ("." & targetDomain) then return true
    return false
end belongsToDomain
