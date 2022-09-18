;------------------------------------------------------------------------------------------------;
; Nome:                                                                                          ;
;   AsmSnake.                                                                                    ;
;                                                                                                ;
; Descrição:                                                                                     ;
;   Um clone do jogo Snake totalmente em assembly x86 compilado                                  ;
;   com o nasm e linkado com o alink.                                                            ;
;                                                                                                ;
; Codado por:                                                                                    ;
;   Willams S. de Sousa (aka will ou osdeving).                                                  ;
;                                                                                                ;
; Assembly com:                                                                                  ;
;   C:\>nasm -f obj -o AsmSnake.obj AsmSnake.asm                                                 ;
;                                                                                                ;
; Link com:                                                                                      ;
;   C:\>alink -oPE -o AsmSnake.exe AsmSnake.obj                                                  ;
;                                                                                                ;
; Download do alink:                                                                             ;
;   http://alink.sourceforge.net/                                                                ;
;                                                                                                ;
; Download do nasm:                                                                              ;
;   http://nasm.sourceforge.net/                                                                 ;
;------------------------------------------------------------------------------------------------;


;------------------------------------------------------------------------------------------------;
; Seção de dados, onde ficam as variáveis globais do programa e as constantes.                   ;
;------------------------------------------------------------------------------------------------;
[SECTION DATA USE32 CLASS=DATA]
	szClassName      DB "ClassName", 0
	szChildClassName DB "ChildClassName", 0
   	szAppName        DB "AsmSnake 0.1", 0
   	szCollision      DB "Você colidiu. :(", 0
   	szAboutMessage   DB "Um clone do jogo AsmSnake.", 0
   	szNewGameMenu    DB "&Novo Jogo", 9, "F9", 0
   	szPauseMenu      DB "&Pause", 9, "F8", 0
   	szExitMenu       DB "&Sair", 9, "F7", 0
   	szVeryEasyMenu   DB "&Muito Fácil", 0
   	szEasyMenu       DB "&Fácil", 0
   	szHardMenu       DB "&Difícil", 0
   	szVeryHardMenu   DB "Muito D&ifícil", 0
   	szAboutMenu      DB "&Sobre", 0
   	szGameMenu       DB "&Jogo", 0
   	szSpeedMenu      DB "&Velocidade", 0
   	szHelpMenu       DB "&Ajuda", 0
   	szFormat         DB "%d", 0
   	szScore          DB "Pontos: ", 0
   	szBufScore       DB "0", 0, 0, 0, 0, 0, 0, 0, 0, 0
   	dwLastIDChecked  DD ID_VERYHARD	 
   	hSpeedMenu       DD 0
   	hInstance        DD 0
   	hWnd             DD 0
   	hDC              DD 0
   	hBufDC           DD 0
   	hBufBmp          DD 0
   	hOldBmp          DD 0
   	pList            DD 0
   	dwSnakeDir       DD RIGHT
   	dwToMove         DD RIGHT
   	dwFoodX          DD -1
   	dwFoodY          DD -1
   	dwSpeed          DD ID_VERYHARD 
	dwAnda			 DD NAO
	dwMudouDir		 DD	NAO
   	bGameLoop        DB 0
   	
   	ID_TIMER         EQU 1000
   	ID_NEWGAME       EQU 5000
	ID_PAUSE         EQU 5001
	ID_EXIT          EQU 5002  
	ID_ABOUT         EQU 5003
	ID_VERYEASY      EQU 400
	ID_EASY          EQU 300
	ID_HARD          EQU 200
	ID_VERYHARD      EQU 100
	
	UP               EQU 1  	
   	RIGHT            EQU 2
   	DOWN             EQU 4
	LEFT             EQU 8
	
	SIM				 EQU 1
	NAO				 EQU 0
	
	GAME_SPEED       EQU 30
	BLOCK_SIZE       EQU 16
   	WINDOW_WIDTH     EQU 36 * BLOCK_SIZE
   	WINDOW_HEIGHT    EQU 24 * BLOCK_SIZE
   	SCORE_HEIGHT     EQU 45


;------------------------------------------------------------------------------------------------;
; Seção de código, o código do programa.                                                         ;
;------------------------------------------------------------------------------------------------;
[SECTION CODE USE32 CLASS=CODE]

..start:
	
	PUSH 0
	CALL [GetModuleHandle]                  ; Obtém a instancia (HINSTANCE) desse programa  
	MOV DWORD [hInstance], EAX              ; e armazena na variável hInstance.
	
	CALL WinMain                            ; Chama função principal, WinMain. 
	
	PUSH 0
	CALL [ExitProcess]                      ; Deve ser chamado ExitProcess no final.

;------------------------------------------------------------------------------------------------;
; Função WinMain.                                                                                ;
; Parâmetros: não.                                                                               ;
; Retorno:    retorna MSG.wParam em EAX.                                                         ;
; Descrição:  Função que cria a janela e executa o loop de mensagens.                            ;
;------------------------------------------------------------------------------------------------;
WinMain:
	PUSH EBP                                ; stack frame.
	MOV EBP, ESP
	
	SUB ESP, 76                             ; Aloca 76 bytes no stack para WNDCLASSEX e MSG.
	
	MOV DWORD [EBP - 48], 48                ; cbSize.
	MOV DWORD [EBP - 44], 32                ; style = CS_OWNDC.  
	MOV DWORD [EBP - 40], WndProc           ; lpfnWndProc.
	MOV DWORD [EBP - 36], 0                 ; cbClsExtra.
	MOV DWORD [EBP - 32], 0                 ; cbWndExtra.
	MOV EAX, DWORD [hInstance] 
	MOV DWORD [EBP - 28], EAX               ; hInstance
	PUSH 32512                              ; lpIconName = IDI_APPLICATION.                              
	PUSH 0                                  ; hInstance = 0. 
	CALL [LoadIcon]
	MOV DWORD [EBP - 24], EAX               ; hIcon.
	MOV DWORD [EBP - 4], EAX                ; hIconSm. 
	PUSH 32512                              ; lpCursorName = IDC_ARROW.
	PUSH 0                                  ; hInstance = 0.
	CALL [LoadCursor]
	MOV DWORD [EBP - 20], EAX               ; hCursor.
	PUSH 4                                  ; BLACK_BRUSH
	CALL [GetStockObject]
	MOV DWORD [EBP - 16], EAX               ; hbrBackground = BLACK_BRUSH
	MOV DWORD [EBP - 12], 0                 ; lpszMenuName.
	MOV DWORD [EBP - 8], szClassName        ; lpszClassName.
	
	LEA EAX, [EBP - 48]                     ; Obtém o endereço da variável WNDCLASSEX.
	PUSH EAX
	CALL [RegisterClassEx]                  ; Registra a classe da janela.
	
	PUSH 0                                  ; lpParam. 
	PUSH DWORD [hInstance]                  ; hInstance.
	PUSH 0                                  ; hMenu.
	PUSH 0                                  ; hWndParent.
	PUSH 100                                ; nHeight.
	PUSH 100                                ; nWidth. 
	PUSH 100                                ; y. - posicao que a janela comeca na tela
	PUSH 100                                ; x. - posicao que a janela comeca na tela
	PUSH 13565952                           ; dwStyle = WS_OVERLAPPEDWINDOW.
	PUSH szAppName                          ; lpWindowName.
	PUSH szClassName                        ; lpClassName.
	PUSH 0                                  ; dwExStyle. 
	CALL [CreateWindowEx]                   ; Cria a janela. 
	MOV DWORD [hWnd], EAX                   ; Obtém o handle da janela criada.
	
	PUSH 5                                  ; SW_SHOW = 5.
	PUSH DWORD [hWnd]                       ; Handle da janela.
	CALL [ShowWindow]                       ; Mostra a janela.
	
	PUSH DWORD [hWnd]                       ; Handle da janela.
	CALL [UpdateWindow]                     ; Atualiza a janela.  

	CALL GameInit                           ; Chama GameInit pra inicializar o jogo.

.message_loop:  
                                            ; Loop de mensagens.
	CALL [GetTickCount]                     ; Obtém o start_tick 
	PUSH EAX                                ; e salva ele na pilha.  
	
	PUSH 1                                  ; wRemoveMsg = PM_REMOVE.
	PUSH 0                                  ; wMsgFilterMax.
   	PUSH 0                                  ; wMsgFilterMin. 
   	PUSH 0                                  ; hWnd.
   	LEA EAX, [EBP - 76]                     ; Obtém o endereço da struct MSG na pilha.  
   	PUSH EAX                                ; lpMsg. 
	CALL [PeekMessage]                      ; Checa se tem mensagens.
	
	CMP EAX, 0
	JNE .handle                             ; Se tem mensagem trata ela. 
	JMP .no_handle                          ; Se não, não trata :).

.handle:
	MOV EAX, DWORD [EBP - 72]               ; Obtém MSG.message.  
	CMP EAX, 18                             ; Testa WM_QUIT.
	JE .exit_message_loop                   ; Se igual WM_QUIT finaliza loop.
	
	LEA EAX, [EBP - 76]                       
	PUSH EAX
	CALL [TranslateMessage]                 ; Traduz a mensagem.  
	
	LEA EAX, [EBP - 76]
	PUSH EAX
	CALL [DispatchMessage]                  ; Despacha a mensagem.

.no_handle:
	CALL GameMain                           ; Chama GameMain.
	
	POP EDX                                 ; Restaura start_tick da pilha.
.tick_loop:
	CALL [GetTickCount]  
	SUB EAX, EDX                            ; Subtrai start_tick do tick atual.
	CMP EAX, GAME_SPEED
	JB .tick_loop                           ; Se menor que 10 chama GetTickCount de novo.                                      
	JMP .message_loop
	
.exit_message_loop:
	CALL GameQuit                           ; Chama GameQuit.
	MOV EAX, DWORD [EBP - 68]               ; Obtém MSG.wParam.  
	MOV ESP, EBP                            ; Desfaz stack frame. 
	POP EBP
	RET                                     ; Retorna.
	
;------------------------------------------------------------------------------------------------;
; Função WndProc.                                                                                ;
; Parâmetros: DWORD hWnd, MSG uMsg, DWORD wParam, DWORD lParam.                                  ;
; Retorno:    O retorno é de acordo com a mensagem tratada (em EAX).                             ;
; Descrição:  Função que trata as mensagens.                                                     ;
;------------------------------------------------------------------------------------------------;
WndProc:
	PUSH EBP                                ; stack frame.  
	MOV EBP, ESP
	
	MOV EDX, DWORD [EBP + 12]               ; Obtém o parâmetro hWnd.
	
	CMP EDX, 2                              ; Compara com WM_DESTROY.
	JE .Destroy
	CMP EDX, 256                            ; Compara com WM_KEYDOWN.
	JE NEAR .KeyDown                              
	CMP EDX, 273                            ; Compara com WM_COMMAND.
	JE .Command
	CMP EDX, 275                            ; Compara com WM_TIMER.
	JE .Timer
	                        
	PUSH DWORD [EBP + 20]                   ; Obtém o parâmetro lParam.  
	PUSH DWORD [EBP + 16]                   ; Obtém o parâmetro wParam.
	PUSH DWORD [EBP + 12]                   ; Obtém o parãmetro uMsg.
	PUSH DWORD [EBP + 8]                    ; Obtém o parâmetro hWnd.
	CALL [DefWindowProc]                    ; Chama DefWindowProc.
	
	MOV ESP, EBP                            ; Desfaz stack frame.  
	POP EBP		
	RET 16                                  ; Retorna ajustando a pilha, stdcall!
	
.Destroy:                                   ; Trata mensagem WM_DESTROY.
	PUSH ID_TIMER
	PUSH DWORD [hWnd]
	CALL [KillTimer]
	
	PUSH 0
	CALL [PostQuitMessage]                  ; Para finalizar o loop de mensagens.
	JMP .return0
	
.Timer:
	CALL MoveSnake
	JMP .return0
	
.Command:                                   
                                           ; Trata mensagem WM_COMMAND.
	MOV EDX, DWORD [EBP + 16]
	
	CMP EDX, ID_ABOUT
	JE .about
	
	CMP EDX, ID_NEWGAME
	JE .new_game
	
	CMP EDX, ID_PAUSE
	JE .pause
	
	CMP EDX, ID_EXIT
	JE .exit
	
	CMP EDX, ID_EASY
	JE .easy
	
	CMP EDX, ID_VERYEASY
	JE NEAR .very_easy
	
	CMP EDX, ID_HARD
	JE NEAR .hard
	
	CMP EDX, ID_VERYHARD
	JE NEAR .very_hard
	
	
	JMP .return0
	
.about:
	PUSH 0
	PUSH szAppName
	PUSH szAboutMessage
	PUSH DWORD [hWnd]
	CALL [MessageBox]
	JMP .return0
	
.new_game:
	JMP .vk_f9

.pause:
	JMP .vk_f8

.exit:
	JMP .vk_f7

.easy:
	PUSH 8                              ; MF_CHECKED.
	PUSH ID_EASY
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	PUSH 0                              ; MF_UNCHECKED.
	PUSH DWORD [dwLastIDChecked]
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	MOV DWORD [dwLastIDChecked], ID_EASY
	
	MOV DWORD [dwSpeed], ID_EASY
	JMP .return0
	
.very_easy:
	PUSH 8                              ; MF_CHECKED.
	PUSH ID_VERYEASY
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	PUSH 0                              ; MF_UNCHECKED.
	PUSH DWORD [dwLastIDChecked]
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	MOV DWORD [dwLastIDChecked], ID_VERYEASY
	
	MOV DWORD [dwSpeed], ID_VERYEASY

	JMP .return0
	
.hard:
	PUSH 8                              ; MF_CHECKED.
	PUSH ID_HARD
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	PUSH 0                              ; MF_UNCHECKED.
	PUSH DWORD [dwLastIDChecked]
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	MOV DWORD [dwLastIDChecked], ID_HARD
	
	MOV DWORD [dwSpeed], ID_HARD
	
	JMP .return0
	
.very_hard:
	PUSH 8                              ; MF_CHECKED.
	PUSH ID_VERYHARD
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	PUSH 0                              ; MF_UNCHECKED.
	PUSH DWORD [dwLastIDChecked]
	PUSH DWORD [hSpeedMenu]
	CALL [CheckMenuItem]
	
	MOV DWORD [dwLastIDChecked], ID_VERYHARD
	
	MOV DWORD [dwSpeed], ID_VERYHARD
	
	JMP .return0
	
.KeyDown:
	MOV EDX, DWORD [EBP + 16]               ; wParam em EDX.
	
	CMP EDX, 37                             ; Compara com VK_LEFT.
	JE .vk_left
	
	;
	; VERIFICA SE AS SETAS FORAM PRESSIONADAS
	;
	
	CMP EDX, 38                             ; Compara com VK_UP.
	JE .vk_up
	
	CMP EDX, 39                             ; Compara com VK_RIGHT.
	JE .vk_right
	
	CMP EDX, 40                             ; Compara com VK_DOWN.
	JE .vk_down
	
	CMP EDX, 120                            ; Compara com VK_F9.
	JE NEAR .vk_f9
	
	CMP EDX, 119                            ; Compara com VK_F8.
	JE NEAR .vk_f8 
	
	CMP EDX, 118                            ; Compara com VK_F7.
	JE NEAR .vk_f7
	
	JMP .return0
		
.vk_left:
	MOV DWORD [dwAnda], SIM
	CMP DWORD [dwToMove], LEFT
	JE .return0
	MOV DWORD [dwToMove], LEFT
	MOV DWORD [dwSnakeDir], LEFT
	MOV DWORD [dwMudouDir], SIM
	JMP .return0

.vk_right:
	MOV DWORD [dwAnda], SIM
	CMP DWORD [dwToMove], RIGHT
	JE .return0
	MOV DWORD [dwToMove], RIGHT
	MOV DWORD [dwSnakeDir], RIGHT
	MOV DWORD [dwMudouDir], SIM
	JMP .return0
	
.vk_up:
	MOV DWORD [dwToMove], UP
	MOV DWORD [dwSnakeDir], UP
	MOV DWORD [dwAnda], SIM
	JMP .return0
	
.vk_down:
	MOV DWORD [dwToMove], DOWN
	MOV DWORD [dwSnakeDir], DOWN
	MOV DWORD [dwAnda], SIM
	JMP .return0
	
.vk_f9:
	CALL NewGame
	JMP .return0

.vk_f8:
	CMP BYTE [bGameLoop], 0
	JE .equal0
	MOV BYTE [bGameLoop], 0
	JMP .return0
.equal0:
	MOV BYTE [bGameLoop], 1
	JMP .return0	

.vk_f7:
	PUSH 0
	CALL [PostQuitMessage]
		
.return0:
	XOR EAX, EAX                            ; Retorna zero.
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET 16                                  ; Retorna ajustando a pilha, stdcall!

;------------------------------------------------------------------------------------------------;
; Função GameInit.                                                                               ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Inicia as variáveis do programa.                                                   ;
;------------------------------------------------------------------------------------------------;
GameInit:
	PUSH EBP                                ; stack frame.
	MOV EBP, ESP
	
	SUB ESP, 32                             ; Aloca espaço para duas estruturas RECT.
	  
	PUSH DWORD [hWnd]
	CALL [GetDC]
	MOV DWORD [hDC], EAX                    ; Obtém o HDC da janela.
	
	PUSH EAX
	CALL [CreateCompatibleDC]               ; Cria o HDC do buffer.
	MOV DWORD [hBufDC], EAX
	
	PUSH WINDOW_HEIGHT + SCORE_HEIGHT
	PUSH WINDOW_WIDTH
	PUSH DWORD [hDC]
	CALL [CreateCompatibleBitmap]
	MOV DWORD [hBufBmp], EAX                ; Cria o bitmap do buffer.
	
	PUSH EAX
	PUSH DWORD [hBufDC]
	CALL [SelectObject]                     ; Seleciona hBufBmp em hBufDC.                       
	MOV DWORD [hOldBmp], EAX                ; Obtém o antigo bitmap.
	
	LEA EAX, [EBP - 16]
	PUSH EAX
	PUSH DWORD [hWnd]
	CALL [GetClientRect]                    ; Obtém o Client Rect.
	
	LEA	EAX, [EBP - 32]
	PUSH EAX
	PUSH DWORD [hWnd]
	CALL [GetWindowRect]                    ; Obtém Window Rect.
	
	MOV	ECX, DWORD [(EBP - 32) + 8]
	SUB	ECX, DWORD [(EBP - 32) + 0]
	SUB	ECX, DWORD [(EBP - 16) + 8]
	ADD	ECX, WINDOW_WIDTH
	MOV DWORD [(EBP - 32) + 8], ECX         ; Pega o tamanho de rcWindow.right.
	
	MOV EDX, DWORD [(EBP - 32) + 12]
	SUB EDX, DWORD [(EBP - 32) + 4]
	SUB EDX, DWORD [(EBP - 16) + 12]
	ADD EDX, WINDOW_HEIGHT + SCORE_HEIGHT
	MOV DWORD [(EBP - 32) + 12], EDX        ; Pega o tamanho de rcWindow.bottom.
	
	
	PUSH 1                                  ; bRepaint = TRUE.
	PUSH DWORD [(EBP - 32) + 12]            ; nHeight.
	PUSH DWORD [(EBP - 32) + 8]             ; nWidth.
	PUSH DWORD [(EBP - 32) + 4]             ; Y.
	PUSH DWORD [(EBP - 32) + 0]             ; X.
	PUSH DWORD [hWnd]                       ; hWnd.
	CALL [MoveWindow]                       ; Redimensiona a janela.
	
	CALL CreateAndInsertMenu
	
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET

;------------------------------------------------------------------------------------------------;
; Função GameMain.                                                                               ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Função de desenho do programa.                                                     ;
;------------------------------------------------------------------------------------------------;
GameMain:
	CALL ClearBackground
		
	PUSH DWORD [pList]
	CALL DrawSnake
	
	PUSH 0x00FFFF							; amarelo
	PUSH DWORD [dwFoodY]
	PUSH DWORD [dwFoodX]
	CALL DrawSquare
	
	CALL DrawScore
	
	PUSH 13369376                           ; dvRop = SRCCOPY.
	PUSH 0                                  ; nYSrc.
	PUSH 0                                  ; nXSrc.
	PUSH DWORD [hBufDC]                     ; hdcSrc.
	PUSH WINDOW_HEIGHT + SCORE_HEIGHT       ; nHeight.
	PUSH WINDOW_WIDTH                       ; nWidth.
	PUSH 0                                  ; nYDest.
	PUSH 0                                  ; nXDest.
	PUSH DWORD [hDC]                        ; hdcDest. 
	CALL [BitBlt]                           ; Desenha o buffer. 
	
	RET

;------------------------------------------------------------------------------------------------;
; Função GameQuit.                                                                               ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Função que deleta os objetos criados.                                              ;
;------------------------------------------------------------------------------------------------;	
GameQuit:
	PUSH DWORD [hOldBmp]
	PUSH DWORD [hBufDC]
	CALL [SelectObject]                     ; Seleciona o antigo bitmap.
	
	PUSH DWORD [hBufBmp]
	CALL [DeleteObject]                     ; Deleta o bitmap do buffer.
	
	PUSH DWORD [hBufDC]
	CALL [DeleteDC]                         ; Deleta o DC do buffer.
	
	PUSH DWORD [pList]
	CALL ListFree                           ; Libera a memória alocada na lista. 
	
	RET
	
;------------------------------------------------------------------------------------------------;
; Função ListLast.                                                                               ;
; Parâmetros: DWORD pList.                                                                       ;
; Retorno:    Retorna em EAX o último nó da lista.                                               ;
; Descrição:  Função que retorna o último nó da lista.                                           ;
;------------------------------------------------------------------------------------------------;
ListLast:
	PUSH EBP                                ; stack frame. 
	MOV EBP, ESP	
	
	CMP DWORD [EBP + 8], 0                  ; Verifica se pList é NULL,
	JE	.return                             ; se for retorna pList.

.walk:
	MOV EAX, DWORD [EBP + 8]
	CMP DWORD [EAX + 8], 0	                ; Se pList.next for NULL retorna.
	JE .return
	
	MOV	ECX, DWORD [EBP + 8]                ; ECX tem pList.
	MOV EDX, DWORD [ECX + 8]                ; EDX tem pList.next.
	MOV	DWORD [EBP + 8], EDX                ; pList = pList.next.  
	JMP .walk

.return:
	MOV	EAX, DWORD [EBP + 8]                ; EAX retorna o último nó da lista.

	MOV ESP, EBP                            ; Desfaz stack frame.
	POP	EBP
	RET	4

;------------------------------------------------------------------------------------------------;
; Função ListAppend.                                                                             ;
; Parâmetros: DWORD pList, DWORD x, DWORD y                                                      ;
; Retorno:    Retorna em EAX o inécio da lista.                                                  ;
; Descrição:  Anexa ao fim da lista.                                                             ;
;------------------------------------------------------------------------------------------------;
ListAppend:
	PUSH EBP                                ; stack frame.   
	MOV EBP, ESP
	SUB ESP, 8                              ; Aloca espaço para dois ponteiros: new_list e last.
	
	PUSH 12                                 ; dwBytes = 12 bytes.
	PUSH 0x0040                             ; uFlags = GPTR. 
	CALL [GlobalAlloc]
	MOV DWORD [EBP - 8], EAX                ; Guarda na variével local new_list.
	
	MOV EAX, DWORD [EBP - 8]
	MOV ECX, DWORD [EBP + 12]
	MOV	DWORD [EAX], ECX                ; new_list.x = x. 

	MOV EDX, DWORD [EBP - 8]
	MOV EAX, DWORD [EBP + 16]
	MOV	DWORD [EDX + 4], EAX            ; new_list.y = y.   

	MOV ECX, DWORD [EBP - 8]
	MOV	DWORD [ECX + 8], 0              ; new_list.next = 0.

	CMP	DWORD [EBP + 8], 0              ; Se pList igual zero retorna new_list.  
	JE .return1

	MOV EDX, DWORD [EBP + 8]                
	PUSH EDX
	CALL ListLast
	MOV	DWORD [EBP - 4], EAX            ; Obtém éltimo né da lista.

	MOV	EAX, DWORD [EBP - 4]
	MOV	ECX, DWORD [EBP - 8]
	MOV	DWORD [EAX + 8], ECX            ; last.next = new_list. 

	MOV EAX, DWORD [EBP + 8]            ; Retorna pList em EAX.
	JMP	.return2

.return1:
	MOV	EAX, DWORD [EBP - 8]

.return2:
	MOV ESP, EBP                        ; Desfaz stack frame.
	POP EBP
	RET 12


;------------------------------------------------------------------------------------------------;
; Função ListFree.                                                                               ;
; Parâmetros: DWORD pList.                                                                       ;
; Retorno:    não.                                                                               ;
; Descrição:  Libera a memória alocada na lista.                                                 ;
;------------------------------------------------------------------------------------------------;
ListFree:
	PUSH EBP                                ; stack frame. 
	MOV EBP, ESP
	PUSH ECX                                ; Aloca espaço na pilha para um ponteiro.  
	
.walk
	CMP	DWORD [EBP + 8], 0                  ; Se pList é 0 enté o retorna.                   
	JE	.Return

	MOV EAX, DWORD [EBP + 8]                
	MOV	DWORD [EBP - 4], EAX                ; Move pList para a variével local.

	MOV ECX, DWORD [EBP + 8]
	MOV EDX, DWORD [ECX + 8]                ; EDX tem pList.next.
	MOV	DWORD [EBP + 8], EDX                ; pList = pList.next.  

	MOV EAX, DWORD [EBP - 4]                 
	PUSH EAX
	CALL [GlobalFree]                       ; Libera pList.

	JMP .walk
	
.Return:
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET 4

;------------------------------------------------------------------------------------------------;
; Função ListDeleteFirst.                                                                        ;
; Parâmetros: DWORD pList.                                                                       ;
; Retorno:    Retorna o inécio da lista.                                                         ;
; Descrição:  Deleta o primeiro né da lista.                                                     ;
;------------------------------------------------------------------------------------------------;
ListDeleteFirst:
	PUSH EBP                                ; stack frame. 
	MOV EBP, ESP
	PUSH ECX                                ; Aloca espaço para um ponteiro. 
	
	CMP DWORD [EBP + 8], 0                  ; Se pList é 0 retorna.  
	JE .return
	
	MOV EAX, DWORD [EBP + 8]
	MOV ECX, DWORD [EAX + 8]
	MOV DWORD [EBP - 4], ECX                ; Coloca pList.next na variével local. 
	
	MOV EDX, DWORD [EBP + 8]
	PUSH EDX
	CALL [GlobalFree]                       ; Deleta pList.
	
	MOV EAX, DWORD [EBP - 4]                ; Move pList.next para retornar em EAX. 

.return
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET 4

;------------------------------------------------------------------------------------------------;
; Função DrawSquare.                                                                             ;
; Parâmetros: DWORD x, DWORD y, DWORD Color.                                                     ;
; Retorno:    não.                                                                               ;
; Descrição Desenha um quadrado da cor Color em x, y.                                            ;
;------------------------------------------------------------------------------------------------;
DrawSquare:
	PUSH EBP                                ; stack frame.
	MOV EBP, ESP
	
	SUB ESP, 4                              ; Aloca espaço pra uma variével HBRUSH.
	
	PUSH EDI                                ; Salva na pilha.
	PUSH ESI                                ; Salva na pilha.
	
	PUSH DWORD [EBP + 16]                   ; Parémetro DWORD Color.
	CALL [CreateSolidBrush]                 ; Cria um HBRUSH com a cor do parémetro Color.
	MOV DWORD [EBP - 4], EAX                ; Guarda HBRUSH na variével local.   
		
	PUSH EAX                                ; HBRUSH. 
	PUSH DWORD [hBufDC]                     ; HDC. 
	CALL [SelectObject]                     ; Seleciona o HBRUSH criado em hBufDC. 
	PUSH EAX                                ; Salva o HBRUSH antigo.
	 
	MOV EAX, DWORD [EBP + 8]                ; Obtém o parémetro x.
	MOV ECX, BLOCK_SIZE                     ; Obtém BLOCK_SIZE.
	MUL ECX                                 ; Multiplica por BLOCK_SIZE (resultado em EDX:EAX).
	MOV EDI, EAX                            ; Salva o resultado em EDI.
	
	MOV EAX, DWORD [EBP + 12]               ; Obtém o parémetro y.
	MOV ECX, BLOCK_SIZE                     ; Obtém BLOCK_SIZE. 
	MUL ECX                                 ; Multiplica por BLOCK_SIZE (resultado em EDX:EAX).
	MOV ESI, EAX                            ; Salva o resultado em ESI.
	
	ADD ESI, BLOCK_SIZE
	PUSH ESI                                ; nBottomRect.
	ADD EDI, BLOCK_SIZE
	PUSH EDI                                ; nRightRect. 
	SUB ESI, BLOCK_SIZE
	PUSH ESI                                ; nTopRect.
	SUB EDI, BLOCK_SIZE
	PUSH EDI                                ; nLeftRect.
	PUSH DWORD [hBufDC]                     ; HDC.
	CALL [Rectangle]                        ; Desenha o reténgulo no hBufDC.
	
	PUSH DWORD [hBufDC]                     ; HDC
	CALL [SelectObject]                     ; Seleciona o HBRUSH antigo que jé esté na pilha.
	
	PUSH DWORD [EBP - 4]                    ; HBRUSH.
	CALL [DeleteObject]                     ; Deleta o HBRUSH que foi criado.
	
	POP ESI                                 ; Restaura.
	POP EDI                                 ; Restaura.
	
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET	12

;------------------------------------------------------------------------------------------------;
; Função CreateSnake.                                                                            ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Função que cria o snake.                                                           ;
;------------------------------------------------------------------------------------------------;
CreateSnake:

	PUSH DWORD [pList]
	CALL ListFree                          ; Libera a memória alocada na lista.
	MOV DWORD [pList], 0
	
	PUSH (WINDOW_HEIGHT / (BLOCK_SIZE + 1 )) ; Posiééo que a nave comeéa na tela
	PUSH (WINDOW_WIDTH / BLOCK_SIZE) / 2 - 1
	PUSH DWORD [pList]
	CALL ListAppend                        ; Anexa na lista. 
	MOV DWORD [pList], EAX

	PUSH (WINDOW_HEIGHT / (BLOCK_SIZE + 1 ))
	PUSH (WINDOW_WIDTH / BLOCK_SIZE) / 2
	PUSH DWORD [pList]
	CALL ListAppend                        ; Anexa na lista. 
	MOV DWORD [pList], EAX

	;PUSH (WINDOW_HEIGHT / (BLOCK_SIZE + 2 ))
	;PUSH (WINDOW_WIDTH / BLOCK_SIZE) / 2
	;PUSH DWORD [pList]
	;CALL ListAppend                        ; Anexa na lista.
	;MOV DWORD [pList], EAX
	
	PUSH (WINDOW_HEIGHT / (BLOCK_SIZE + 1 ))
	PUSH (WINDOW_WIDTH / BLOCK_SIZE) / 2 + 1
	PUSH DWORD [pList]
	CALL ListAppend                        ; Anexa na lista.
	MOV DWORD [pList], EAX
	
	MOV DWORD [dwSnakeDir], RIGHT

	RET
	
;------------------------------------------------------------------------------------------------;
; Função DrawSnake.                                                                              ;
; Parâmetros: DWORD pList.                                                                       ;
; Retorno:    não.                                                                               ;
; Descrição:  Desenha o snake.                                                                   ;
;------------------------------------------------------------------------------------------------;
DrawSnake:
	PUSH EBP                                ; stack frame. 
	MOV EBP, ESP
	PUSH ECX                                ; Aloca espaço na pilha para um ponteiro.  
	
.walk
	CMP	DWORD [EBP + 8], 0             		; Se pList é 0 entéo retorna.                   
	JE	.return

	MOV EAX, DWORD [EBP + 8]                
	MOV	DWORD [EBP - 4], EAX           	 	; Move pList para a variével local.

	MOV ECX, DWORD [EBP + 8]
	MOV EDX, DWORD [ECX + 8]
	MOV	DWORD [EBP + 8], EDX            	; pList = pList.next.  

	PUSH 0x0000FF                           ; cor vermelha.
	MOV EAX, DWORD [EBP - 4]
	PUSH DWORD [EAX + 4]                    ; y. 
	PUSH DWORD [EAX]                        ; x.
	CALL DrawSquare                         ; Desenha o quadrado.
	
	JMP .walk
	
.return:
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET 4

;------------------------------------------------------------------------------------------------;
; Função MoveSnake.                                                                              ;
; Parâmetros: não                                                                                ;
; Retorno:    não.                                                                               ;
; Descrição:  Move o snake.                                                                      ;
;------------------------------------------------------------------------------------------------;
MoveSnake:
	PUSH EBP                                ; stack frame. 
	MOV EBP, ESP
	
	SUB ESP, 12
	
	MOV EAX, DWORD [dwSnakeDir]
	CMP EAX, DOWN
	JB .left_shift
	SHR EAX, 2
	JMP .continue1
.left_shift:
	SHL EAX, 2
.continue1:
	CMP DWORD [dwToMove], EAX
	JE .equal
	JMP .continue2
.equal:
	MOV EDX, DWORD [dwSnakeDir]
	MOV DWORD [dwToMove], EDX
.continue2:
	
	CMP DWORD [pList], 0
	JE NEAR .return
	
	CMP BYTE [bGameLoop], 0
	JE NEAR .return                         ; Se bGameLoop é NULL não move o snake.

	CMP DWORD [dwAnda], NAO
	JE NEAR .return                         ; Se dwAnda for NULL, não move a nave.
	
	MOV DWORD [dwAnda], NAO
	
	CALL CheckBorderCollision
	CMP EAX, 0
	JNE NEAR .return
	
	PUSH DWORD [pList]
	CALL ListLast                           ; Obtém éltimo né da lista. 
	
	MOV EDX, DWORD [EAX]                    
	MOV DWORD [EBP - 4], EDX                ; Guarda o y do éltimo né no y local.
	MOV EDX, DWORD [EAX + 4] 
	MOV DWORD [EBP - 8], EDX                ; Guarda o x do éltimo né no x local.
	
	MOV EDX, DWORD [dwToMove]
	CMP EDX, RIGHT
	JE .r
	CMP EDX, LEFT
	JE .l
	CMP EDX, UP
	JE .u
	CMP EDX, DOWN
	JE .d
	JMP .continue
		
.d:                                         ; Direééo DOWN.
	INC DWORD [EBP - 8]                     ; Incrementa variével y.
	JMP .continue
.u:                                         ; Direééo UP.  
	DEC DWORD [EBP - 8]                     ; Decrementa variével y.
	JMP .continue
.r:                                         ; Direééo RIGHT.
	INC DWORD [EBP - 4]                     ; Incrementa variével x.
	JMP .continue
.l:                                         ; Direééo LEFT.
	DEC DWORD [EBP - 4]                     ; Decrementa variével x.

.continue:

	PUSH DWORD [EBP - 8]
	PUSH DWORD [EBP - 4]
	PUSH DWORD [pList]
	
	PUSH DWORD [EBP - 8]                    ; Variével local y. 
	PUSH DWORD [EBP - 4]                    ; Variével local x. 
	PUSH DWORD [pList]
	CALL ListAppend                         ; Anexa um novo né.                          
	MOV DWORD [pList], EAX
	
	MOV EAX, DWORD [EBP - 4]
	MOV EDX, DWORD [EBP - 8]
	
	CMP EAX, DWORD [dwFoodX]
	JNE .not_grow
	CMP EDX, DWORD [dwFoodY]
	JNE .not_grow
	
	CALL PutFood
	
	PUSH szBufScore
	CALL a2dw
	
	ADD EAX, 100
	
	PUSH EAX
	PUSH szFormat
	PUSH szBufScore
	CALL [wsprintf]
	
	CALL DrawScore
	
	
	JMP .grow
	
.not_grow:
	;CMP DWORD [dwMudouDir], SIM
	;JE .return
	MOV EAX, DWORD [pList]
	PUSH 0
	PUSH DWORD [EAX + 4]
	PUSH DWORD [EAX]
	CALL DrawSquare                         ; Deleta graficamente o primeiro né.
	
	PUSH DWORD [pList]
	CALL ListDeleteFirst                    ; Deleta o primeiro né.
	MOV DWORD [pList], EAX                  
	

.grow:
	MOV EDX, DWORD [dwToMove]
	MOV DWORD [dwSnakeDir], EDX

.return:
	MOV DWORD [dwMudouDir], NAO
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET

;------------------------------------------------------------------------------------------------;
; Função CheckBorderCollision.                                                                   ;
; Parâmetros: não.                                                                               ;
; Retorno:    Retorna em EAX true ou false.                                                      ;
; Descrição:  Checa coliséo do snaken nas bordas.                                                ;
;------------------------------------------------------------------------------------------------;
CheckBorderCollision:
	PUSH EBP                                ; stack frame. 
	MOV EBP, ESP
	SUB ESP, 8                              ; Aloca espaço na pilha para um ponteiro.
	
	PUSH DWORD [pList]
	CALL ListLast
	
	MOV EDX, DWORD [dwSnakeDir]
		
	CMP DWORD [EAX], 0
	JE .collision_left
	CMP DWORD [EAX], (WINDOW_WIDTH / BLOCK_SIZE) - 1
	JE .collision_right
	CMP DWORD [EAX + 4], 0
	JE .collision_up
	CMP DWORD [EAX + 4], (WINDOW_HEIGHT / BLOCK_SIZE) - 1
	JE .collision_down
	
	JMP .return0
	 
.collision_right:
	CMP EDX, RIGHT
	JE .collision
	JMP .return0
	
.collision_left:
	CMP EDX, LEFT
	JE .collision
	JMP .return0
	
.collision_up:
	CMP EDX, UP
	JE .collision
	JMP .return0
	
.collision_down:
	CMP EDX, DOWN
	JE .collision
	JMP .return0
	
.collision:
	;PUSH ID_TIMER
	;PUSH DWORD [hWnd]
	;CALL [KillTimer]
	
	PUSH 0
	PUSH szAppName
	PUSH szCollision
	PUSH 0
	CALL [MessageBox]
	
	MOV EAX, 1
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET
	
.return0:
	XOR EAX, EAX
	MOV ESP, EBP                            ; Desfaz stack frame.
	POP EBP
	RET

;------------------------------------------------------------------------------------------------;
; Função NewGame.                                                                                ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Inicia um novo jogo.                                                               ;
;------------------------------------------------------------------------------------------------;
NewGame:
	CALL CreateSnake
	
	CALL ClearBackground
	
	CALL PutFood
	
	PUSH ID_TIMER
	PUSH DWORD [hWnd]
	CALL [KillTimer]
	
	PUSH 0
	PUSH DWORD [dwSpeed]
	PUSH ID_TIMER
	PUSH DWORD [hWnd]
	CALL [SetTimer]
	
	MOV BYTE [bGameLoop], 1
	
	MOV DWORD [szBufScore], 0x0030
	CALL DrawScore
	
	RET

;------------------------------------------------------------------------------------------------;
; Função PutFood.                                                                                ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Coloca uma comida na janela.                                                       ;
;------------------------------------------------------------------------------------------------;
PutFood:
	PUSH EBP
	MOV EBP, ESP
	SUB ESP, 8

.loop
	MOV EAX, DWORD [pList]
	MOV DWORD [EBP - 8], EAX
	
	PUSH (WINDOW_WIDTH / BLOCK_SIZE)
	CALL Random
	MOV DWORD [dwFoodX], EAX
	
	PUSH (WINDOW_HEIGHT / BLOCK_SIZE)
	CALL Random
	MOV DWORD [dwFoodY], EAX
	
.walk
	CMP	DWORD [EBP - 8], 0                  ; Se pList é 0 entéo retorna.                   
	JE	.break

	MOV EAX, DWORD [EBP - 8]                
	MOV	DWORD [EBP - 4], EAX                ; Move pList para a variével local.

	MOV ECX, DWORD [EBP - 8]
	MOV EDX, DWORD [ECX + 8]                ; EDX tem pList.next.
	MOV	DWORD [EBP - 8], EDX                ; pList = pList.next.  

	MOV EAX, DWORD [EBP - 4]                 
	
	MOV EDX, DWORD [dwFoodX]
	CMP EDX, DWORD [EAX]
	JNE .walk
	
	MOV EDX, DWORD [dwFoodY]
	CMP EDX, DWORD [EAX + 4]
	JNE .walk
	
	JMP .loop	


.break:
	PUSH 0x00FFFF
	PUSH DWORD [dwFoodY]
	PUSH DWORD [dwFoodX]
	CALL DrawSquare
	
	MOV	ESP, EBP
	POP EBP
	RET
	
;------------------------------------------------------------------------------------------------;
; Função ClearBackground.                                                                        ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Apaga o fundo.                                                                     ;
;------------------------------------------------------------------------------------------------;
ClearBackground:
	PUSH EBP                                ; stack frame.
	MOV EBP, ESP
	
	SUB ESP, 4                              ; Aloca espaço pra uma variével HBRUSH.
	
		
	PUSH 0
	CALL [CreateSolidBrush]
	MOV DWORD [EBP - 4], EAX                ; Guarda HBRUSH na variével local.
	
	PUSH EAX                                ; HBRUSH. 
	PUSH DWORD [hBufDC]                     ; HDC. 
	CALL [SelectObject]                     ; Seleciona o HBRUSH criado em hBufDC. 
	PUSH EAX                                ; Salva o HBRUSH antigo.
	
	PUSH WINDOW_HEIGHT + SCORE_HEIGHT
	PUSH WINDOW_WIDTH
	PUSH 0
	PUSH 0
	PUSH DWORD [hBufDC]                     ; HDC.
	CALL [Rectangle]                        ; Desenha o reténgulo no hBufDC.
	
	PUSH DWORD [hBufDC]                     ; HDC
	CALL [SelectObject]                     ; Seleciona o HBRUSH antigo que jé esté na pilha.
	
	PUSH DWORD [EBP - 4]                    ; HBRUSH.
	CALL [DeleteObject]                     ; Deleta o HBRUSH que foi criado.
	
	MOV	ESP, EBP
	POP EBP
	RET
	

;------------------------------------------------------------------------------------------------;
; Função CreateAndInsertMenu.                                                                    ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Cria e insere o menu do programa.                                                  ;
;------------------------------------------------------------------------------------------------;
CreateAndInsertMenu:
	PUSH EBP
	MOV EBP, ESP
	SUB ESP, 12
	
	CALL [CreateMenu]
	MOV DWORD [EBP - 4], EAX
	CALL [CreateMenu]
	MOV DWORD [EBP - 8], EAX
	CALL [CreateMenu]
	MOV DWORD [EBP - 12], EAX
	CALL [CreateMenu]
	MOV DWORD [hSpeedMenu], EAX
	
	;
	; hMenu2
	;
	PUSH szNewGameMenu                ;
	PUSH ID_NEWGAME                   ; 
	PUSH 0                            ; MF_STRING
	PUSH DWORD [EBP - 8]
	CALL [AppendMenu]
	
	PUSH szPauseMenu                  ;
	PUSH ID_PAUSE                     ; 
	PUSH 0                            ; MF_STRING
	PUSH DWORD [EBP - 8]
	CALL [AppendMenu]
	
	PUSH 0                            ;
	PUSH 0                            ; 
	PUSH 2048                         ; MF_SEPARATOR
	PUSH DWORD [EBP - 8]
	CALL [AppendMenu]
	
	PUSH szExitMenu                   ;
	PUSH ID_EXIT                      ; 
	PUSH 0                            ; MF_STRING
	PUSH DWORD [EBP - 8]
	CALL [AppendMenu]
	
	;
	; hMenu
	;
	PUSH szVeryEasyMenu               ;
	PUSH ID_VERYEASY                  ; 
	PUSH 8                            ; MF_STRING | MF_CHECKED
	PUSH DWORD [hSpeedMenu]
	CALL [AppendMenu]
	
	PUSH szEasyMenu                   ;
	PUSH ID_EASY                      ; 
	PUSH 0                            ; MF_STRING
	PUSH DWORD [hSpeedMenu]
	CALL [AppendMenu]
	
	PUSH szHardMenu                   ;
	PUSH ID_HARD                      ; 
	PUSH 0                            ; MF_SEPARATOR
	PUSH DWORD [hSpeedMenu]
	CALL [AppendMenu]
	
	PUSH szVeryHardMenu               ;
	PUSH ID_VERYHARD                  ; 
	PUSH 0                            ; MF_STRING
	PUSH DWORD [hSpeedMenu]
	CALL [AppendMenu]
	
	;
	; hMenu3
	;
	PUSH szAboutMenu                  ;
	PUSH ID_ABOUT                     ; 
	PUSH 0                            ; MF_STRING
	PUSH DWORD [EBP - 12]
	CALL [AppendMenu]
	
	;
	; hMenu1
	;
	PUSH szGameMenu                   ;
	PUSH DWORD [EBP - 8]              ; 
	PUSH 16                           ; MF_STRING | MF_POPUP
	PUSH DWORD [EBP - 4]
	CALL [AppendMenu]
	
	PUSH szSpeedMenu                  ;
	PUSH DWORD [hSpeedMenu]           ; 
	PUSH 16                           ; MF_STRING | MF_POPUP
	PUSH DWORD [EBP - 4]
	CALL [AppendMenu]
		
	PUSH szAboutMenu                  ;
	PUSH DWORD [EBP - 12]             ; 
	PUSH 16                           ; MF_STRING | MF_POPUP
	PUSH DWORD [EBP - 4]
	CALL [AppendMenu]
	
	PUSH DWORD [EBP - 4]
	PUSH DWORD [hWnd]
	CALL [SetMenu]	
	
	MOV ESP, EBP
	POP EBP
	RET

;------------------------------------------------------------------------------------------------;
; Função DrawScore.                                                                              ;
; Parâmetros: não.                                                                               ;
; Retorno:    não.                                                                               ;
; Descrição:  Desenha o placar.                                                                  ;
;------------------------------------------------------------------------------------------------;
DrawScore:
	PUSH 6                          ; WHITE_PEN
	CALL [GetStockObject]
	
	PUSH EAX
	PUSH DWORD [hBufDC]
	CALL [SelectObject]             ; Seleciona WHITE_PEN no buffer dc.
	PUSH EAX                        ; Salva o HPEN antigo.
	
	PUSH 0
	PUSH WINDOW_HEIGHT + 1
	PUSH 0
	PUSH DWORD [hBufDC]
	CALL [MoveToEx]
	
	PUSH WINDOW_HEIGHT + 1
	PUSH WINDOW_WIDTH
	PUSH DWORD [hBufDC]
	CALL [LineTo]
	
	PUSH 1                          ; TRANSPARENT.
	PUSH DWORD [hBufDC]
	CALL [SetBkMode]
	
	PUSH 0xFFFFFF                   ; Branco.
	PUSH DWORD [hBufDC]
	CALL [SetTextColor]
	
	PUSH 7
	PUSH szScore
	PUSH WINDOW_HEIGHT + 4
	PUSH 4
	PUSH DWORD [hBufDC]
	CALL [TextOut]
	
	PUSH szBufScore
	CALL [lstrlen]
	PUSH EAX
	PUSH szBufScore
	PUSH WINDOW_HEIGHT + 4
	PUSH 100
	PUSH DWORD [hBufDC]
	CALL [TextOut]               ; Desenha o placar.
		
	PUSH DWORD [hBufDC]
	CALL [SelectObject]
	
	RET

;------------------------------------------------------------------------------------------------;
; Função a2dw.                                                                                   ;
; Parâmetros: DWORD lpszString.                                                                  ;
; Retorno:    Retorna o valor em EAX.                                                            ;
; Descrição:  Função que converte uma string em um DWORD.                                        ;
;------------------------------------------------------------------------------------------------;
a2dw:
	PUSH EBP
	MOV EBP, ESP
	
	PUSH ESI
   	PUSH EDI
   	XOR EAX, EAX
   	MOV ESI, DWORD [EBP + 8]
   	XOR ECX, ECX
   	XOR EDX, EDX
   	MOV AL, [ESI]
   	INC ESI
   	CMP AL, 2DH
   	JNE .proceed
   	MOV AL, BYTE  [ESI]
   	NOT EDX
   	INC ESI
   	JMP .proceed

.BBB: 
   	SUB AL, 30H
   	LEA ECX,  [ECX + 4 * ECX]
   	LEA ECX,  [EAX + 2 * ECX]
   	MOV AL, BYTE [ESI]
   	INC ESI

.proceed:
	OR AL, AL
   	JNE .BBB
   	LEA EAX, [EDX + ECX]
   	XOR EAX, EDX
   	POP EDI
   	POP ESI
    
    MOV ESP, EBP
    POP EBP
    RET 4

;------------------------------------------------------------------------------------------------;
; Função Random.                                                                                 ;
; Parâmetros: DWORD teto.                                                                        ;
; Retorno:    Retorna o némero aleatério em EAX.                                                 ;
; Descrição:  Gera um némero aleatério.                                                          ;
;------------------------------------------------------------------------------------------------;
Random:
	PUSH EBP
	MOV EBP, ESP
	SUB ESP, 4
	
	PUSH EDX
	
	CALL [GetTickCount]
	MOV DWORD [EBP - 4], EAX
	
	XOR EDX, EDX        
    PUSH 127773
    DIV DWORD [ESP]
    PUSH EAX
    MOV EAX, 16807    
	MUL EDX
	POP EDX
	PUSH EAX        
  	MOV EAX, 2836              
	MUL EDX
	POP EDX                
	SUB EDX, EAX
	MOV EAX, EDX
	MOV DWORD [EBP - 4], EDX
	PUSH DWORD [EBP + 8]
	MOV EDX, 0
	DIV DWORD [ESP]
	ADD ESP, 8
	MOV EAX, EDX
	
	POP EDX
	
	MOV ESP, EBP
	POP EBP
	RET	4

;------------------------------------------------------------------------------------------------;
; Funéées importadas das dlls do Windows.                                                        ;
;------------------------------------------------------------------------------------------------;	
IMPORT ExitProcess  kernel32.dll
IMPORT MessageBox user32.dll MessageBoxA
IMPORT GetCommandLine kernel32.dll GetCommandLineA
IMPORT RegisterClassEx user32.dll RegisterClassExA
IMPORT CreateWindowEx user32.dll CreateWindowExA
IMPORT ShowWindow user32.dll
IMPORT GetMessage user32.dll GetMessageA
IMPORT TranslateMessage user32.dll
IMPORT DispatchMessage user32.dll DispatchMessageA
IMPORT DefWindowProc user32.dll DefWindowProcA
IMPORT UpdateWindow user32.dll
IMPORT LoadIcon user32.dll LoadIconA
IMPORT LoadCursor user32.dll LoadCursorA
IMPORT GetModuleHandle kernel32.dll GetModuleHandleA
IMPORT PostQuitMessage user32.dll
IMPORT CreateSolidBrush gdi32.dll
IMPORT GetTickCount kernel32.dll
IMPORT PeekMessage user32.dll PeekMessageA
IMPORT GetDC user32.dll
IMPORT CreateCompatibleDC gdi32.dll
IMPORT CreateCompatibleBitmap gdi32.dll
IMPORT SelectObject gdi32.dll
IMPORT GetWindowRect user32.dll
IMPORT GetClientRect user32.dll
IMPORT MoveWindow user32.dll
IMPORT DeleteDC gdi32.dll
IMPORT DeleteObject gdi32.dll
IMPORT BitBlt gdi32.dll
IMPORT Rectangle gdi32.dll
IMPORT GlobalAlloc kernel32.dll
IMPORT GlobalFree kernel32.dll
IMPORT GetTickCount kernel32.dll
IMPORT AppendMenu user32.dll AppendMenuA
IMPORT CreateMenu user32.dll
IMPORT SetMenu user32.dll
IMPORT GetStockObject gdi32.dll
IMPORT MoveToEx gdi32.dll
IMPORT LineTo gdi32.dll
IMPORT SetTextColor gdi32.dll
IMPORT SetBkMode gdi32.dll
IMPORT TextOut gdi32.dll TextOutA
IMPORT lstrlen kernel32.dll lstrlenA
IMPORT CheckMenuItem user32.dll
IMPORT KillTimer user32.dll
IMPORT SetTimer user32.dll
IMPORT wsprintf user32.dll wsprintfA

EXTERN KillTimer
EXTERN SetTimer
EXTERN wsprintf
EXTERN CheckMenuItem
EXTERN lstrlen
EXTERN TextOut
EXTERN SetBkMode
EXTERN SetTextColor
EXTERN LineTo
EXTERN MoveToEx
EXTERN GetStockObject
EXTERN SetMenu
EXTERN CreateMenu
EXTERN AppendMenu
EXTERN GetTickCount
EXTERN GlobalFree
EXTERN GlobalAlloc
EXTERN Rectangle
EXTERN BitBlt
EXTERN DeleteObject
EXTERN DeleteDC
EXTERN MoveWindow
EXTERN GetWindowRect
EXTERN GetClientRect
EXTERN GetDC
EXTERN CreateCompatibleDC
EXTERN CreateCompatibleBitmap
EXTERN SelectObject
EXTERN PeekMessage
EXTERN GetTickCount
EXTERN CreateSolidBrush
EXTERN PostQuitMessage
EXTERN GetModuleHandle
EXTERN LoadIcon
EXTERN LoadCursor  
EXTERN UpdateWindow
EXTERN DefWindowProc
EXTERN DispatchMessage
EXTERN TranslateMessage
EXTERN ShowWindow
EXTERN GetMessage
EXTERN RegisterClassEx
EXTERN CreateWindowEx
EXTERN GetCommandLine
EXTERN ExitProcess
EXTERN MessageBox
