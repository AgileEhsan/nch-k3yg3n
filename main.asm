    format PE GUI 4.0
    entry initialize
    include '\fasm\include\win32ax.inc'

LICENSE_ID          =       1
LICENSE_KEY         =       2
PRODUCT_ID          =       3
COPY_BTN            =       4
INFO_BTN            =       5
NEXT_BTN            =       6
ABOUT_OK            =       7
GET_PROC_ADDRESS    =   0x8f900864
LOAD_LIBRARY        =   0x00635164
KERNEL32_HASH       =   0x29A1244C

macro pascal_string [bytes]
{
    .   dw  .size
        du  bytes
    .size = ($-.-2) shr 1
}

struc name_table [strings, func]
{
    common
        .size = 0
    forward
        local ..temp_label
        dd ..temp_label, func
        .size = .size+1
    forward
        label ..temp_label
        db strings, 0
}

macro string_table [string]
{
    common
        .size = 0
    forward
        local ..temp_label
        dd ..temp_label
        .size = .size+1
    forward
        label ..temp_label
        db string, 0
}

macro init_dll dll_id, dll_name, [func_name]
{
    common
        label dll_id
        .size = 0
        .dll db dll_name, 0
        label .functions
    forward
        .size = .size + 1
    forward
        dd func_name, fn#func_name
    forward
        label func_name dword
        .str db `func_name, 0
    forward
        label fn#func_name dword
        dd  0
}

macro push [reg] { forward push reg }
macro pop [reg] { reverse pop reg }

macro load_dll [dll_id]
{
    forward
    push ebx
    push esi
    push edx
    local ..next, ..load_loop
..next:
    mov eax, esp
    invoke fnLoadLibraryEx, dll_id#.dll, 0, 0
    mov esi, eax
    xor ebx, ebx
..load_loop:
    invoke fnGetProcAddress, esi, dword [dll_id#.functions+ebx*8]
    mov edx, [dll_id#.functions+ebx*8+4]
    mov [edx], eax
    inc ebx
    cmp ebx, dll_id#.size
    jl ..load_loop
    pop edx
    pop esi
    pop ebx
}


section '.data' data readable writeable

    fnGetProcAddress    dd  0
    fnLoadLibraryEx     dd  0

    ;
    ; Declaring imports in a dll
    ; init_dll [dll_id], [dll_name], [function_1], [function_2], ...
    ;
    ; For Example
    ; init_dll user32, 'user32.dll', MessageBoxTimeoutA
    ; init_dll kernel32, 'kernel32.dll', ExitProcess
    ;

    init_dll kernel32, 'kernel32.dll',\
        ExitProcess, GlobalAlloc, GlobalFree, GlobalLock, GlobalUnlock

    init_dll user32, 'user32.dll',\
        DialogBoxParamA, SendMessageA, PostQuitMessage,\
        GetDlgItem, CreateWindowExA, GetDlgItemInt,\
        OpenClipboard, SetClipboardData, CloseClipboard,\
        EmptyClipboard, EndDialog, LoadIconA

    init_dll ntdll, 'ntdll.dll',\
        RtlRandom, NtQuerySystemTime

    szApps name_table 'WavePad Sound Editor', wavepad,\
            'Switch Sound Converter', switch_sound,\
            'VideoPad Video Editor', video_pad,\
            'Express Rip', express_rip,\
            'Prism Video Converter', prism,\
            'Mixpad Multitrack', mixpad,\
            'Express Burn', express_burn,\
            'Doxillion', doxillion,\
            'KeyBlaze Typing', keyblaze,\
            'Pixillion', pixillion

    szMagicA:
        string_table "mnbvaq", "cxzlbr", "kjhgct", "fdsady", "poiueu", "ytrefo", "wqalgx", "ksjdhv", "hfgbif"

    szMagicB:
        string_table "qazwja", "sxedkf", "crfvlg", "tgbymh", "hnujni", "miklop", "plokpc"

    szKey           db  'abcdefXX', 0
    szInformation   db  'Any integer greater than 10**8', 0
    szToolClass     db  'tooltips_class32', 0
    szLicense       rb  64

    hLicenseID      dd  0
    hProductBox     dd  0
    hCopyBtn        dd  0
    hInfoBtn        dd  0
    hLicenseKey     dd  0

    tool_info:
        .cbSize     dd  .size
        .uFlags     dd  TTF_CENTERTIP or TTF_IDISHWND or TTF_SUBCLASS
        .hWnd       dd  ?
        .uId        dd  ?
        .rect       RECT ?
        .hInst      dd  ?
        .lpszText   dd  szInformation
        .lParam     dd  ?
    .size           =   $-tool_info

    szInfo          db  'K3yG3n for NCH-Software. Written by x0r19x91 :-)'


section '.text' code executable

jenkins_hash:
    push ebx
    xor eax, eax
@@:
    movzx ebx, byte [esi]
    or bl, bl
    jz @f
    add eax, ebx
    mov ebx, eax
    shl ebx, 10
    add eax, ebx
    mov ebx, eax
    shr ebx, 6
    xor eax, ebx
    inc esi
    jmp @b
@@:
    mov ebx, eax
    shl ebx, 3
    add eax, ebx
    mov ebx, eax
    shr ebx, 11
    xor eax, ebx
    mov ebx, eax
    shl ebx, 15
    add eax, ebx
    pop ebx
    ret

hash:
    push ebx
    xor eax, eax
    sub esi, 2
@@:
    inc esi
    inc esi
    movzx ebx, word [esi]
    or ebx, ebx
    jz .ret
    ror eax, 9
    xor eax, ebx
    cmp ebx, 0x61
    jl @b
    cmp ebx, 0x7b
    jge @b
    xor eax, ebx
    sub ebx, 0x20
    xor eax, ebx
    jmp @b
.ret:
    pop ebx
    ret

initialize:
    mov eax, [fs:0x30]
    mov eax, [eax+12]
    mov ebx, [eax+0x1c]

.find:
    mov esi, [ebx+0x20]
    call hash
    cmp eax, KERNEL32_HASH
    jz .found
    mov ebx, [ebx]
    jmp .find

.found:
    mov ebx, [ebx+8]
    mov eax, [ebx+0x3c]
    mov eax, [eax+ebx+24+96]
    add eax, ebx
    push eax
    mov ecx, [eax+24]
    mov ebp, [eax+32]   ; name table
    mov edx, [eax+36]   ; ordinal table
    add edx, ebx
    add ebp, ebx
    xor edi, edi

.search_loop:
    mov esi, [ebp]
    add esi, ebx
    call jenkins_hash
    cmp eax, LOAD_LIBRARY
    jnz .is_proc_addr
    inc edi
    movzx eax, word [edx]
    mov [fnLoadLibraryEx], eax
    jmp .next_func

.is_proc_addr:
    cmp eax, GET_PROC_ADDRESS
    jnz .next_func
    inc edi
    movzx eax, word [edx]
    mov [fnGetProcAddress], eax

.next_func:
    add edx, 2
    add ebp, 4
    cmp edi, 2
    jz @f
    dec ecx
    jnz .search_loop

@@:
    pop edi
    mov edx, [edi+28]
    add edx, ebx
    mov eax, [fnLoadLibraryEx]
    mov ecx, [edx+eax*4]
    add ecx, ebx
    mov [fnLoadLibraryEx], ecx
    mov eax, [fnGetProcAddress]
    mov ecx, [edx+eax*4]
    add ecx, ebx
    mov [fnGetProcAddress], ecx

;
;   Entry Point
;
main:
    load_dll ntdll, kernel32, user32
    mov eax, [fs:0x30]
    invoke fnDialogBoxParamA, dword [eax+8], 1, 0, dialog_callback, 0
    invoke fnExitProcess, 0

dialog_callback:
    mov ebp, [esp+4]
    mov ecx, [esp+8]
    cmp ecx, WM_CLOSE
    jz on_close
    cmp ecx, WM_INITDIALOG
    jz on_init
    cmp ecx, WM_COMMAND
    jz on_command
    cmp ecx, WM_CHAR
    jz on_keyup

.default:
    xor eax, eax
    ret

on_keyup:
    cmp dword [esp+12], 0x1b
    jnz dialog_callback.default
    invoke fnPostQuitMessage, 0
    mov eax, 1
    ret

on_init:
    ; Initialize the combo box now
    mov [tool_info.hWnd], ebp
    invoke fnGetDlgItem, ebp, LICENSE_ID
    mov [hLicenseID], eax
    mov [tool_info.uId], eax
    invoke fnGetDlgItem, ebp, PRODUCT_ID
    mov [hProductBox], eax
    invoke fnGetDlgItem, ebp, LICENSE_KEY
    mov [hLicenseKey], eax
    invoke fnGetDlgItem, ebp, COPY_BTN
    mov [hCopyBtn], eax
    invoke fnGetDlgItem, ebp, INFO_BTN
    mov [hInfoBtn], eax
    mov eax, [fs:0x30]
    invoke fnLoadIconA, dword [eax+8], 1
    mov ebx, eax
    invoke fnSendMessageA, ebp, WM_SETICON, 1, ebx
    xor ebx, ebx

.init_combo_box:
    invoke fnSendMessageA, [hProductBox], CB_ADDSTRING, 0, dword [szApps+ebx*8]
    invoke fnSendMessageA, [hProductBox], CB_SETITEMDATA, eax, ebx

.next_item:
    inc ebx
    cmp ebx, szApps.size
    jl .init_combo_box

    invoke fnSendMessageA, [hProductBox], CB_SETCURSEL, 0, 0

    ; Create a tooltip
    mov eax, [fs:0x30]
    mov eax, [eax+8]
    invoke fnCreateWindowExA, 0, szToolClass, 0, \
        WS_POPUP or 1,\
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,\
        CW_USEDEFAULT, ebp, 0, eax, 0
    invoke fnSendMessageA, eax, TTM_ADDTOOL, 0, tool_info
    mov eax, 1
    ret

on_close:
    invoke fnPostQuitMessage, 0
    ret

copy_license:
    invoke fnSendMessageA, [hLicenseKey], WM_GETTEXTLENGTH, 0, 0
    or eax, eax
    jz .ret
    invoke fnGlobalAlloc, GHND, 32
    mov ebx, eax
    invoke fnOpenClipboard, ebp
    or eax, eax
    jz .free
    invoke fnEmptyClipboard
    invoke fnGlobalLock, ebx
    invoke fnSendMessageA, [hLicenseKey], WM_GETTEXT, 32, eax
    invoke fnGlobalUnlock, ebx
    invoke fnSetClipboardData, CF_TEXT, ebx
    invoke fnCloseClipboard
    mov eax, 1
    ret

.free:
    invoke fnGlobalFree, ebx
    mov eax, 1
    ret

.ret:
    xor eax, eax
    ret

on_command:
    mov eax, [esp+12]
    shr eax, 16
    cmp eax, EN_CHANGE
    jz update_license
    cmp eax, BN_CLICKED
    jz handle_buttons

.is_combo:
    mov eax, [hProductBox]
    cmp eax, [esp+0x10]
    jnz .ret
    mov eax, [esp+12]
    shr eax, 16
    cmp eax, CBN_SELCHANGE
    jz update_license

.ret:
    xor eax, eax
    ret

handle_buttons:
    mov ax, [esp+12]
    cmp ax, COPY_BTN
    jz copy_license
    cmp ax, INFO_BTN
    jz show_info
    cmp ax, NEXT_BTN
    jnz on_command.ret

next_license:
    invoke fnSendMessageA, [hLicenseKey], WM_GETTEXTLENGTH, 0, 0
    or eax, eax
    jz random_digits
    call random
    mov ecx, 0x1a
    div ecx
    add edx, 0x61
    mov [szKey+6], dl
    call random
    mov ecx, 0x1a
    div ecx
    add edx, 0x61
    mov [szKey+7], dl
    jmp update_license.next

random_digits:
    rept 9 index:1 {
        call random
        mov ecx, 10
        div ecx
        add dl, 0x30
        mov [szLicense+index], dl
    }
    call random
    mov ecx, 9
    div ecx
    add dl, 0x31
    mov [szLicense], dl
    mov [szLicense+9], 0
    invoke fnSendMessageA, [hLicenseID], WM_SETTEXT, 0, szLicense
    mov eax, 1
    ret

update_license:
    invoke fnSendMessageA, [hLicenseID], WM_GETTEXTLENGTH, 0, 0
    or eax, eax
    jz clear_text
    invoke fnGetDlgItemInt, ebp, LICENSE_ID, 0, 0
    cmp eax, 100000000
    jle clear_text
    mov ebx, eax
    invoke fnSendMessageA, [hProductBox], CB_GETCURSEL, 0, 0
    or eax, eax
    js clear_text
    invoke fnSendMessageA, [hProductBox], CB_GETITEMDATA, eax, 0
    or eax, eax
    js clear_text
    mov esi, eax

    mov al, 0x60
    mov edi, szKey
    mov ecx, 6

.initialize:
    inc al
    stosb
    dec ecx
    jnz .initialize

    ; Generate License Key :)
    mov eax, ebx
    cdq
    mov ecx, 100
    div ecx
    call dword [szApps+esi*8+4]

    ; The last two letters can be any letter combination
    mov eax, 'clay'
    mov dword [szKey+4], eax

.next:
    invoke fnSendMessageA, [hLicenseID], WM_GETTEXT, 64, szLicense
    lea edi, [szLicense+eax]
    mov al, '-'
    stosb
    mov esi, szKey
    movsd
    movsd
    movsb
    invoke fnSendMessageA, [hLicenseKey], WM_SETTEXT, 0, szLicense
    mov eax, 1
    ret

clear_text:
    invoke fnSendMessageA, [hLicenseKey], WM_SETTEXT, 0, ""

.ret:
    mov eax, 1
    ret

about_callback:
    cmp dword [esp+8], WM_INITDIALOG
    jz clear_text.ret
    cmp dword [esp+8], WM_CLOSE
    jz .kill
    cmp dword [esp+8], WM_COMMAND
    clc
    jnz .ret
    movzx eax, word [esp+12]
    cmp eax, ABOUT_OK
    jnz .ret

.kill:
    invoke fnEndDialog, dword [esp+8], eax
    stc

.ret:
    setc al
    movzx eax, al
    ret

show_info:
    mov eax, [fs:0x30]
    invoke fnDialogBoxParamA, dword [eax+8], 2, ebp, about_callback, 0
    mov eax, 1
    ret

shift_string:
    push eax, edx, ecx
    rept 6 offset:0 {
        movzx eax, byte [edi+offset]
        movzx edx, byte [esi+offset]
        lea eax, [eax+edx-0xc2]
        cdq
        mov ecx, 26
        div ecx
        add edx, 0x61
        mov [edi+offset], dl
    }
    pop eax, edx, ecx
    ret

random:
    xor eax, eax
    invoke fnNtQuerySystemTime, esp, eax, eax
    invoke fnRtlRandom, esp
    and eax, 0x7fffffff
    cdq
    add esp, 8
    ret

;
; Arguments: eax
;
generic:
    mov edi, szKey
    rept 4 {
        mov ecx, 9
        cdq
        div ecx
        mov esi, [szMagicA+edx*4]
        call shift_string
        cdq
        mov ecx, 7
        div ecx
        mov esi, [szMagicB+edx*4]
        call shift_string
    }
    ret

pixillion:
    call generic
    mov esi, [szMagicA+2*4]
    call shift_string
    mov esi, [szMagicB+3*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

keyblaze:
    call generic
    mov esi, [szMagicA+8*4]
    call shift_string
    mov esi, [szMagicB+5*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

doxillion:
    call generic
    mov esi, [szMagicA+5*4]
    call shift_string
    mov esi, [szMagicB+5*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

express_burn:
    call generic
    mov esi, [szMagicA+3*4]
    call shift_string
    mov esi, [szMagicB+2*4]
    call shift_string
    mov ecx, 9
    cdq
    div ecx
    mov esi, [szMagicA+edx*4]
    call shift_string
    cdq
    mov ecx, 7
    div ecx
    mov esi, [szMagicB+edx*4]
    call shift_string
    ret

mixpad:
    call generic
    mov esi, [szMagicA+1*4]
    call shift_string
    mov esi, [szMagicB+4*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

prism:
    call generic
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB+3*4]
    call shift_string
    mov ecx, 9
    cdq
    div ecx
    mov esi, [szMagicA+edx*4]
    call shift_string
    cdq
    mov ecx, 7
    div ecx
    mov esi, [szMagicB+edx*4]
    call shift_string
    ret

;
; Arguments: eax
wavepad:
    call generic
    mov esi, [szMagicA+7*4]
    call shift_string
    mov esi, [szMagicB+1*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

switch_sound:
    call generic
    mov esi, [szMagicA+7*4]
    call shift_string
    mov esi, [szMagicB+2*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

video_pad:
    call generic
    mov esi, [szMagicB+3*4]
    call shift_string
    mov esi, [szMagicA+5*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret

express_rip:
    call generic
    mov esi, [szMagicA+5*4]
    call shift_string
    mov esi, [szMagicB+2*4]
    call shift_string
    mov esi, [szMagicA]
    call shift_string
    mov esi, [szMagicB]
    call shift_string
    ret


section '.res' resource data readable

    directory RT_DIALOG, dialogs,\
        RT_MANIFEST, manifest,\
        RT_ICON, icons,\
        RT_GROUP_ICON, group

    resource dialogs,\
        1, LANG_ENGLISH or SUBLANG_DEFAULT, main_dialog,\
        2, LANG_ENGLISH or SUBLANG_DEFAULT, about_dialog

    resource manifest,\
        1, LANG_ENGLISH or SUBLANG_DEFAULT, visual_style

    resource icons,\
        1, LANG_ENGLISH or SUBLANG_DEFAULT, main_icon

    resource group,\
        1, LANG_ENGLISH or SUBLANG_DEFAULT, group_icon

    icon group_icon, main_icon, 'magic.ico'

    dialog about_dialog, 'About', 0, 0, 157, 60,\
        DS_MODALFRAME or DS_SETFONT or DS_CENTER\
         or DS_FIXEDSYS or WS_POPUP or WS_CAPTION\
         or WS_SYSMENU, 0, , 'MS Shell Dlg 2', 8

        dialogitem 'Static', 1, 0, 14, 14, 32, 32, \
            SS_ICON or WS_CHILD or WS_VISIBLE

        dialogitem 'static', 'NCH Software KeyG3n', 0, 55, 14, 91, 8,\
            SS_LEFT or WS_CHILD or WS_VISIBLE or WS_GROUP

        dialogitem 'static', ' ~ by x0r19x91', 0, 55, 26, 91, 8,\
            SS_LEFT or WS_CHILD or WS_VISIBLE or WS_GROUP

        dialogitem 'button', 'OK', ABOUT_OK, 55, 39, 50, 14,\
            WS_CHILD or WS_VISIBLE or WS_GROUP or WS_TABSTOP

    enddialog

    dialog main_dialog, '[ ~ NCH K3yG3n ~ ]', 0, 0, 215+20, 76+20+4+1,\
        DS_MODALFRAME or DS_CENTER or WS_OVERLAPPED or DS_CENTER or \
        WS_VISIBLE or WS_CAPTION or WS_SYSMENU, 0,,'MS Shell Dlg 2', 8

        dialogitem 'Edit', '', LICENSE_ID, 24, 12, 64, 12,\
            ES_LEFT or ES_AUTOHSCROLL or ES_NUMBER or WS_CHILD or \
            WS_VISIBLE or WS_BORDER or WS_TABSTOP

        dialogitem 'ComboBox', '', PRODUCT_ID, 133, 12, 72+20, 12,\
            CBS_DROPDOWNLIST or WS_TABSTOP or WS_CHILD or WS_VISIBLE or CBS_SORT

        dialogitem 'Button', 'License Key', 0, 9, 30, 196+20, 36+10,\
            BS_GROUPBOX or WS_CHILD or WS_VISIBLE

        dialogitem 'Static', '', LICENSE_KEY, 40, 45, 131+20, 12,\
            SS_CENTER or WS_CHILD or WS_VISIBLE or\
            WS_TABSTOP or WS_GROUP

        dialogitem 'Static',\
            '[*] Note - ID is any integer greater than 10**8',\
            0, 11, 60, 196+15, 15, SS_CENTER or WS_CHILD or WS_VISIBLE or WS_GROUP

        dialogitem 'Static', 'ID', 0, 10, 14, 8, 9,\
            SS_CENTER or WS_VISIBLE or WS_CHILD

        dialogitem 'Static', 'Product', 0, 99, 14, 26, 9,\
            SS_CENTER or WS_VISIBLE or WS_CHILD

        dialogitem 'Button', 'Copy to Clipboard', COPY_BTN, 9, 30+36+10+4, 70, 15,\
            WS_CHILD or WS_TABSTOP or WS_VISIBLE

        dialogitem 'Button', 'Next License', NEXT_BTN, 9+70+3, 30+36+10+4, 70, 15,\
            WS_CHILD or WS_TABSTOP or WS_VISIBLE

        dialogitem 'Button', 'About', INFO_BTN, 196+20-60, 30+36+10+4, 70, 15,\
            WS_CHILD or WS_TABSTOP or WS_VISIBLE

    enddialog

    resdata visual_style
        db "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>"
        db "<assembly xmlns='urn:schemas-microsoft-com:asm.v1' manifestVersion='1.0'>"
        db '<trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">'
        db '<security>'
        db '<requestedPrivileges>'
        db "<requestedExecutionLevel level='asInvoker' uiAccess='false' />"
        db '</requestedPrivileges>'
        db '</security>'
        db '</trustInfo>'

        db '<dependency>'
        db '<dependentAssembly>'
        db "<assemblyIdentity type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*' />"
        db "</dependentAssembly>"
        db '</dependency>'
        db '</assembly>'
    endres
