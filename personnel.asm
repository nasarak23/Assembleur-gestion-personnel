
;NOMS ET PRENOM
;GNAHOUI Merveille
;RAKOTOARISOA Nasandratriniavo 

section .data

; menu principal pour réaliser les différentes actions
menu db "1 Enregistrer", 10
     db "2 Lister", 10
     db "3 Supprimer", 10
     db "4 Plus age / Plus jeune", 10
     db "5 Moyenne", 10
     db "6 Quitter", 10
     db "Votre choix : "
menu_len equ $ - menu ;longueur du menu

choix db 0,0 ; buffer pour lire 2 caractères (1 choix du menu + \n)


;Gestion des personnes
max_personnes equ 50 ;j'ai fixé le nombre maximal de personnes à enregistrer à 50
taille_personne equ 24 ;20 octets pour le nom + 4 octets pour l'age

personnes db 1200 dup(0); 50*24 = 1200 octets réservés (tableau de personnes)
nb_personnes dd 0; compteur pour le nombre de personnes enregistrées


;Message
;nom
msg_nom db "Nom :"
msg_nom_len equ $ - msg_nom
;age
msg_age db "Age :"
msg_age_len equ $ - msg_age

age_buffer db 4 dup(0); buffer temporaire pour l'age
age_affiche db 0,0,10; comporte deux chiffres puis un retour à la ligne

;numéro d'enregistrement
num db 0,0,10

;pour le retour à la ligne
newline db 10

; pour espace
space db " "


;Variables de suppression
msg_supprimer db "Suppression de la personne:", 10
msg_supprimer_len equ $ - msg_supprimer

delete_buffer db 3 dup(0); varaible de récupération du choix de l'utilisateur

;NOtifiication de suppresseion
msg_sup db "Personne a été supprimée"
msg_sup_len equ $ - msg_sup

;Message d'erreur lorque le personnel n'existe pas
msg_erreur db "Cette personne n'existe pas !", 10
msg_erreur_len equ $ - msg_erreur


;Variables de plus/moins age
msg_plus_moins_age db "Plus âgée et plus jeune:", 10
msg_plus_moins_age_len equ $ - msg_plus_moins_age

index_max dd 0
index_min dd 0

;Variables de moyenne d'age
msg_moyenne db "Age en moyenne:", 10
msg_moyenne_len equ $ - msg_moyenne

msg_err_moy db "Il n'y a aucun personnel", 10
msg_err_moy_len equ $ - msg_err_moy





section .text
global _start

_start:

menu_loop:

     ;Aller à la ligne
     mov eax, 4
     mov ebx, 1
     mov ecx, newline
     mov edx, 1
     int 80h

     ;Aller à la ligne
     mov eax, 4
     mov ebx, 1
     mov ecx, newline
     mov edx, 1
     int 80h


     ;Affichage du menu
     mov eax, 4 ;sys write
     mov ebx, 1 ;stdout
     mov ecx, menu ;adresse du texte
     mov edx, menu_len ;longeur
     int 0x80

     ;Lecture du choix
     mov eax, 3 ; read
     mov ebx, 0 ; lecture à partir du clavier
     mov ecx, choix ;choix est l'adresse du buffer de l'élément à lire
     mov edx, 2; on lire au maximum 2 octects (le chiffre + entrée)
     int 0x80



     ;Comparaison avec le caractère 6 pour quitter
     mov al, [choix]; on enregistre le 1er caractère tapé par l'utilisateur à l'adresse choix dans al
     
     cmp al, '6'; comparaison entre ce caractère et 6
     je quitter; si al égal à 6 on quitte le programme

     cmp al, '1'; si l'utilisateur tape 1    
     je enregistrer; on récupère la saisie de l'utilisateur pour l'age et le nom qu'on enregistre

     cmp al, '2'; si user tape 2
     je lister ; listing du personnel enregistrer par l'utilisateur 

     cmp al, '3'; 
     je supprimer; suppression de personnel choisi en fonction de son numéro

     cmp al, '4'
     je plus_moins_age; affichage du personnel le plus agé et le personnel le moins agé

     cmp al, '5'
     je moyenne; affichage de le moyenne des âges

     ;sinon on revient au menu
     jmp menu_loop ; à la fin de chaque opération, on revient au menu (boucle)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ENREGISTREMENT DU PERSONNEL;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
enregistrer:
     ; on vérifie si le nombre maximum de personnes est atteint
     mov eax, [nb_personnes]; on charge le nombre actuel de personnes
     cmp eax, max_personnes
     je menu_loop; si c'est égal on revient au menu

     ;Sinon on calcul l'adresse de la nouvelle personne
     mov eax, [nb_personnes]; on charge le nb actuel de personnes
     imul eax, taille_personne; nb_personnes * taille_personne
     add eax, personnes; on ajoute le résultat dans eax à l'adresse de personnes pour obtenir l'@ de la personne enregistrée

     mov esi, eax

     ;Affichage du mot Nom :
     mov eax, 4
     mov ebx, 1
     mov ecx, msg_nom
     mov edx, msg_nom_len
     int 0x80

     ;Lecture de nom (saisie utilisateur)
     mov eax, 3
     mov ebx, 0
     mov ecx, esi; adresse du bloc personne
     mov edx, 20; le max de caraxtère à lire est 20
     int 0x80; interruption 

;Suppression de l'effet \n de la touche entrer après saisie du nom
     mov edi, esi 

supprimer_nl:
     cmp byte [edi], 10
     je remplace_nl
     inc edi
     jmp supprimer_nl

remplace_nl:
     mov byte [edi], 0


     ;Affichage du mot Age :
     mov eax, 4
     mov ebx, 1
     mov ecx, msg_age
     mov edx, msg_age_len
     int 0x80

     ;lecture de l'age (saisie utilisateur)
     mov eax, 3
     mov ebx, 0
     mov ecx, age_buffer
     mov edx, 4
     int 0x80

     ;

     ;Conversion du code ASCII de l'âge en entier
     mov eax, 0

     ;Premier chiffre
     xor ebx, ebx; Pour mettre ebx à 0
     mov bl, [age_buffer]; charge le caractère ascii
     sub bl, '0'; 
     mov eax, ebx

     ; on vérifie si le deuxième caractère est \n
     cmp byte [age_buffer+1], 10
     je age_un_chiffre

     ;sinon 2 chiffres
     imul eax, 10
     xor ebx, ebx
     mov bl, [age_buffer+1]; deuxième chiffre     
     sub bl, '0'
     add eax, ebx; eax contient maintenant l'âge

     age_un_chiffre:; cette fonction ne contient rien donc si l'age comporte un chiffre, on affiche juste ce chiffre
     

     ;Stockage de l'âge
     mov ebx, esi
     add ebx, 20
     mov [ebx], eax


     ;On incrémente le nombre de personnes
     inc dword [nb_personnes]; nb_personnes++

     ; retour au menu
     jmp menu_loop




;;;;;;;;;;;;;;;;;LISTER LES PERSONNES ENREGISTREES;;;;;;;;;;;;;;;;;;;;;;;;;
lister:

    mov ecx, [nb_personnes]
    cmp ecx, 0
    je menu_loop

    mov esi, personnes
    mov edi, 1 ; les numéros de listing commencent par 1

boucle_liste:

     ; affichage du numéro d'enregistrement
     mov eax, edi
     add al, '0'; conversion ASCII
     mov [num], al
     mov byte [num+1], ' '
     mov byte [num+2], 0 

     mov eax, 4
     mov ebx, 1
     push ecx
     mov ecx, num
     mov edx, 2; chiffre + espace
     int 80h
     pop ecx

     ; afficher nom
     mov eax, 4
     mov ebx, 1
     mov edx, 20
     push ecx ; sauvegarder compteur
     mov ecx, esi
     int 0x80
     pop ecx; restaurer compteur

     ;affichage espace
     mov eax, 4
     mov ebx, 1
     mov edx, 1
     push ecx
     mov ecx, space
     int 0x80
     pop ecx

     ;age
     mov ebx, esi
     add ebx, 20
     mov eax, [ebx]
     ; conversion en entier
     xor edx, edx; on met edx à 0
     mov ebx, 10
     idiv ebx

     ; si quotient = 0 on affiche l'age avec un chiffre pour ne pas avoir des choses comme : 04
     cmp eax, 0
     je affichage_age_un_chiffre

     ;sinon si 2 chiiffres
     add al, '0'
     mov [age_affiche], al

     add dl, '0'
     mov [age_affiche+1], dl

     ;affichage age
     mov eax, 4
     mov ebx, 1
     push ecx
     mov ecx, age_affiche
     mov edx, 2 ;on affiche les deux chiffres de l'age
     int 80h
     pop ecx

     jmp fin_affichage_age

     

affichage_age_un_chiffre:
     add dl, '0'
     mov [age_affiche], dl

     mov eax, 4
     mov ebx, 1
     push ecx
     mov ecx, age_affiche
     mov edx, 1 ; on affiche un seul caractère
     int 80h
     pop ecx


fin_affichage_age: ; on ne fait rien 


     ;retour à la ligne
     mov eax, 4
     mov ebx, 1
     push ecx
     mov ecx, newline
     mov edx, 1
     int 80h
     pop ecx

     ;fin boucle
     add esi, taille_personne
     inc edi
     dec ecx
     jne boucle_liste
     jmp menu_loop


;;;;;;;;;;;;;;;;;;;;;;;; SUPPRESSION DU PERSONNEL;;;;;;;;;;;;;;;;;;;;
supprimer:
     ;affichage du message de suppression
     mov eax, 4
     mov ebx, 1
     mov ecx, msg_supprimer
     mov edx, msg_supprimer_len
     int 80h

     ;lecture du numéro entrer par l'utilisateur
     mov eax, 3
     mov ebx, 0
     mov ecx, delete_buffer
     mov edx, 3
     int 80h
    
     ; conversion du code ascii en entier
     xor eax, eax
     mov al, [delete_buffer]
     sub al, '0'

     ;on vérifie si le numéro entrer existe
     ;si plus petit que 1 : invalide
     cmp eax, 1
     jl suppression_invalide

     ;si plus grand que le nombre de personnes disponibles: invalide
     mov ebx, [nb_personnes]
     cmp eax, ebx
     jg suppression_invalide


     ;index = num - 1
     dec eax
     mov edi, eax

     ;nombre d'élement à déplacer
     mov ecx, [nb_personnes]
     sub ecx, edi
     dec ecx
     cmp ecx, 0
     je fin_suppression 


decalage_bloc:
    ; calcul adresse destination
    mov eax, edi
    imul eax, taille_personne
    mov esi, personnes
    add esi, eax; esi est le bloc courant

    ; calcul adresse source
    add eax, taille_personne
    mov edx, personnes
    add edx, eax; edx est le bloc suivant       

    ; copie des 24 octets un par un
    mov ebx, 0

copie_octet:
    mov al, [edx+ebx]
    mov [esi+ebx], al
    inc ebx
    cmp ebx, taille_personne
    jl copie_octet

    inc edi
    dec ecx
    cmp ecx, 0
    jne decalage_bloc


fin_suppression:
    ; décrémenter nb_personnes
    dec dword [nb_personnes]
    ;Message de suppression 
    jmp lister; affichage de la nouvelle liste de personne


suppression_invalide:
    ; affichage message d'erreur
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_erreur
    mov edx, msg_erreur_len
    int 80h
    jmp menu_loop








;;;;;;;;;;;;;;;;;;;;;;;;;;;;PERSONNEL PLUS AGE / PLUS JEUNE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
plus_moins_age:

    ;message d'affichage
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_plus_moins_age
    mov edx, msg_plus_moins_age_len
    int 80h

    ;vérifier qu'il y a au moins une personne
    mov ecx, [nb_personnes]
    cmp ecx, 0
    je menu_loop

    ;initialisation à personne 0
    mov esi, personnes
    mov eax, [esi+20] ; age première personne

    mov ebx, eax; ebx = max_age
    mov edx, eax; edx = min_age

    mov dword [index_max], 0
    mov dword [index_min], 0

    mov edi, 0; index courant       


;Boucle de comparaison
boucle_age:

    ; age courant (de la première personne)
    mov eax, [esi+20]

    ;comparaison avec max
    cmp eax, ebx
    jle verifier_min

    mov ebx, eax
    mov [index_max], edi

verifier_min:

    ; comparer avec min
    cmp eax, edx
    jge suite

    mov edx, eax
    mov [index_min], edi


suite:

     add esi, taille_personne
     inc edi

     mov eax, [nb_personnes]
     cmp edi, eax
     jl boucle_age

     
          
     mov edi, [index_max]

     mov eax, edi
     imul eax, taille_personne
     mov esi, personnes
     add esi, eax

     ; affichage numéro
     mov eax, edi
     inc eax
     add al, '0'
     mov [num], al
     mov byte [num+1], ' '

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, num
     mov edx, 2
     int 80h
     pop ecx

     ; affichage nom
     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, esi
     mov edx, 20
     int 80h
     pop ecx

     ;espace
     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, space
     mov edx, 1
     int 80h
     pop ecx

     ; affichage de l'age
     mov eax, [esi+20]
     xor edx, edx
     mov ebx, 10
     idiv ebx

     cmp eax, 0
     je age_un_chiffre_max

     add al, '0'
     mov [age_affiche], al
     add dl, '0'
     mov [age_affiche+1], dl

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, age_affiche
     mov edx, 2
     int 80h
     pop ecx

     jmp apres_age_max

age_un_chiffre_max:
     add dl, '0'
     mov [age_affiche], dl

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, age_affiche
     mov edx, 1
     int 80h
     pop ecx

apres_age_max:

     ;retour ligne
     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, newline
     mov edx, 1
     int 80h
     pop ecx


     ;affichage du plus jeune
     mov edi, [index_min]

     mov eax, edi
     imul eax, taille_personne
     mov esi, personnes
     add esi, eax

     ; afficher numéro
     mov eax, edi
     inc eax
     add al, '0'
     mov [num], al
     mov byte [num+1], ' '

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, num
     mov edx, 2
     int 80h
     pop ecx

     ; afficher nom
     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, esi
     mov edx, 20
     int 80h
     pop ecx

     ; espace
     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, space
     mov edx, 1
     int 80h
     pop ecx

     ; afficher âge (même logique)
     mov eax, [esi+20]
     xor edx, edx
     mov ebx, 10
     idiv ebx

     cmp eax, 0
     je age_un_chiffre_min

     add al, '0'
     mov [age_affiche], al
     add dl, '0'
     mov [age_affiche+1], dl

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, age_affiche
     mov edx, 2
     int 80h
     pop ecx

     jmp fin_age_min

age_un_chiffre_min:
     add dl, '0'
     mov [age_affiche], dl

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, age_affiche
     mov edx, 1
     int 80h
     pop ecx

fin_age_min:

     push ecx
     mov eax, 4
     mov ebx, 1
     mov ecx, newline
     mov edx, 1
     int 80h
     pop ecx

     jmp menu_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;MOYENNE DES AGE;;;;;;;;;;;;;;;;;;;;;;;;;;;
moyenne:

     ;afficher message
     mov eax, 4
     mov ebx, 1
     mov ecx, msg_moyenne
     mov edx, msg_moyenne_len
     int 80h

     ;si nb_personnes = 0
     mov ecx, [nb_personnes]
     cmp ecx, 0
     je moyenne_zero


;Sinon on switch vers le calcul
;Somme des ages
     mov esi, personnes
     xor eax, eax; eax va contenir la somme
     mov edi, 0; index

boucle_somme:

     add eax, [esi+20]; somme += age

     add esi, taille_personne
     inc edi

     mov ebx, [nb_personnes]
     cmp edi, ebx
     jl boucle_somme

   
     ;on divise la somme par le nombre de personnes
     xor edx, edx
     mov ebx, [nb_personnes]
     idiv ebx ; eax contiendra la moyenne

     ;Affichage de la moyenne
     ; conversion en ASCII 
     xor edx, edx ; on met edx à 0
     mov ebx, 10
     idiv ebx

     cmp eax, 0
     je moyenne_un_chiffre

     add al, '0'
     mov [age_affiche], al
     add dl, '0'
     mov [age_affiche+1], dl

     mov eax, 4
     mov ebx, 1
     mov ecx, age_affiche
     mov edx, 2
     int 80h
     jmp fin_moyenne

moyenne_un_chiffre:

    add dl, '0'
    mov [age_affiche], dl

    mov eax, 4
    mov ebx, 1
    mov ecx, age_affiche
    mov edx, 1
    int 80h

fin_moyenne:

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 80h
    jmp menu_loop


moyenne_zero:

    mov byte [age_affiche], '0'

    mov eax, 4
    mov ebx, 1
    mov ecx, age_affiche
    mov edx, 1
    int 80h

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 80h

    jmp menu_loop




;;;;;;;;;;;;;;;;;;;;;;;;FIN DU PROGRAMME;;;;;;;;;;;;;;;;;;;;;;;;;;
quitter:
     mov eax, 1      
     mov ebx, 0      
     int 0x80        
