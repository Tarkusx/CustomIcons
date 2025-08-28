-- ========================================
-- Custom Icons Addon Enhanced pour Classic WoW 1.12
-- Addon d'icônes flottantes personnalisables
-- FIXED: Dropdown pagination to handle 40+ icons
-- ========================================

-- Table principale de l'addon
CustomIcons = {}
CustomIcons.iconesFlottantes = {}
CustomIcons.verrouillee = false -- État de verrouillage global des icônes
CustomIcons.pageActuelle = 1 -- Page actuelle du dropdown
CustomIcons.iconsParPage = 15 -- Nombre d'icônes par page (max safe = 15)

-- Paramètres par défaut - MODIFIER CES VALEURS POUR LES DÉFAUTS
local parametresDefaut = {
    icones = {},
    verrouillee = false,
    profilActuel = "Défaut"
}

-- Liste des icônes disponibles - AJOUTER DE NOUVELLES ICÔNES ICI
local iconesDisponibles = {
    "a",
    "all_g_left",
    "all_g_right", 
    "all_missing",
    "b",
    "down",
    "home",
    "left",
    "ps_c_back",
    "ps_c_back2",
    "ps_c_options",
    "ps_c_share",
    "ps_c_system",
    "ps_r_circle",
    "ps_r_cross",
    "ps_r_square",
    "ps_r_triangle",
    "ps_s_l1",
    "ps_s_l2",
    "ps_s_l3",
    "ps_s_r1",
    "ps_s_r2",
    "ps_s_r3",
    "right",
    "switch_c_back",
    "switch_c_forward",
    "switch_c_share",
    "up",
    "x",
    "xbox_c_back",
    "xbox_c_forward",
    "xbox_c_options",
    "xbox_c_share",
    "xbox_c_system",
    "xbox_s_lb",
    "xbox_s_lsb",
    "xbox_s_lt",
    "xbox_s_rb",
    "xbox_s_rsb",
    "y"
}

-- ========================================
-- FONCTIONS UTILITAIRES POUR DROPDOWN
-- ========================================

-- Calculer le nombre total de pages
function CustomIcons:ObtenirNombrePages()
    return math.ceil(table.getn(iconesDisponibles) / self.iconsParPage)
end

-- Obtenir les icônes pour la page actuelle
function CustomIcons:ObtenirIconesPourPage(page)
    local debut = (page - 1) * self.iconsParPage + 1
    local fin = math.min(page * self.iconsParPage, table.getn(iconesDisponibles))
    local iconesPourPage = {}
    
    for i = debut, fin do
        table.insert(iconesPourPage, iconesDisponibles[i])
    end
    
    return iconesPourPage
end

-- Initialiser le dropdown avec pagination
function CustomIcons:InitialiserDropdownPagine()
    return function()
        local nombrePages = CustomIcons:ObtenirNombrePages()
        
        -- Ajouter les boutons de navigation si plus d'une page
        if nombrePages > 1 then
            -- Bouton page précédente
            if CustomIcons.pageActuelle > 1 then
                local info = {}
                info.text = "< Page Précédente"
                info.value = "PREV_PAGE"
                info.func = function()
                    CustomIcons.pageActuelle = CustomIcons.pageActuelle - 1
                    UIDropDownMenu_Initialize(CustomIcons.menuDeroulant, CustomIcons:InitialiserDropdownPagine())
                    UIDropDownMenu_SetText("Page " .. CustomIcons.pageActuelle .. "/" .. nombrePages, CustomIcons.menuDeroulant)
                end
                info.notCheckable = true
                UIDropDownMenu_AddButton(info)
            end
            
            -- Indicateur de page actuelle
            local info = {}
            info.text = "--- Page " .. CustomIcons.pageActuelle .. "/" .. nombrePages .. " ---"
            info.value = "PAGE_INFO"
            info.func = function() end
            info.notCheckable = true
            info.disabled = true
            UIDropDownMenu_AddButton(info)
        end
        
        -- Ajouter les icônes pour la page actuelle
        local iconesPourPage = CustomIcons:ObtenirIconesPourPage(CustomIcons.pageActuelle)
        for i, nomIcone in ipairs(iconesPourPage) do
            local info = {}
            info.text = nomIcone
            info.value = nomIcone
            info.func = function()
                UIDropDownMenu_SetSelectedValue(CustomIcons.menuDeroulant, this.value)
                UIDropDownMenu_SetText(this.value, CustomIcons.menuDeroulant)
                CustomIcons:MettreAJourApercu(this.value)
            end
            UIDropDownMenu_AddButton(info)
        end
        
        -- Ajouter les boutons de navigation si plus d'une page (suite)
        if nombrePages > 1 then
            -- Bouton page suivante
            if CustomIcons.pageActuelle < nombrePages then
                local info = {}
                info.text = "Page Suivante >"
                info.value = "NEXT_PAGE"
                info.func = function()
                    CustomIcons.pageActuelle = CustomIcons.pageActuelle + 1
                    UIDropDownMenu_Initialize(CustomIcons.menuDeroulant, CustomIcons:InitialiserDropdownPagine())
                    UIDropDownMenu_SetText("Page " .. CustomIcons.pageActuelle .. "/" .. nombrePages, CustomIcons.menuDeroulant)
                end
                info.notCheckable = true
                UIDropDownMenu_AddButton(info)
            end
        end
    end
end

-- ========================================
-- INITIALISATION DE L'ADDON
-- ========================================

-- Initialiser l'addon
function CustomIcons:AuChargement(frame)
    -- Enregistrer les événements
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("VARIABLES_LOADED")
    
    -- Créer les commandes slash - MODIFIER LES COMMANDES ICI
    SLASH_CUSTOMICONS1 = "/cic"
    SlashCmdList["CUSTOMICONS"] = function()
        CustomIcons:BasculerFenetrePrincipale()
    end
end

-- Gestionnaire d'événements
function CustomIcons:SurEvenement()
    if event == "ADDON_LOADED" and arg1 == "CustomIcons" then
        -- Initialiser les variables sauvegardées
        if not CustomIconsDB then
            CustomIconsDB = {}
        end
        
        -- Fusionner avec les défauts
        for cle, valeur in pairs(parametresDefaut) do
            if CustomIconsDB[cle] == nil then
                CustomIconsDB[cle] = valeur
            end
        end
        
        -- Restaurer les icônes sauvegardées
        self:RestaurerIcones()
        
    elseif event == "VARIABLES_LOADED" then
        -- Initialisation supplémentaire si nécessaire
    end
end

-- ========================================
-- CRÉATION DE L'INTERFACE UTILISATEUR
-- ========================================

-- Créer la fenêtre principale
function CustomIcons:CreerFenetrePrincipale()
    if self.fenetrePrincipale then return end
    
    -- Fenêtre principale - MODIFIER LA TAILLE/POSITION DE LA FENÊTRE ICI
    local fenetre = CreateFrame("Frame", "CustomIconsMainFrame", UIParent)
    fenetre:SetWidth(380)
    fenetre:SetHeight(420)
    fenetre:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    fenetre:SetFrameStrata("DIALOG")
    fenetre:SetMovable(true)
    fenetre:EnableMouse(true)
    
    -- Arrière-plan - MODIFIER L'APPARENCE ICI
    fenetre:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    fenetre:SetBackdropColor(0.2, 0.2, 0.2, 1) -- Gris foncé opaque
    fenetre:SetBackdropBorderColor(0, 0, 0, 1) -- Bordure noire
    
    -- Logo en haut - MODIFIER LA POSITION DU LOGO ICI
    local logo = fenetre:CreateTexture(nil, "ARTWORK")
    logo:SetWidth(32)
    logo:SetHeight(32)
    logo:SetPoint("TOP", fenetre, "TOP", 0, -25)
    logo:SetTexture("Interface\\AddOns\\CustomIcons\\icons\\logo")
    
    -- Titre - MODIFIER LE TEXTE DU TITRE ICI
    local titre = fenetre:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titre:SetPoint("TOP", logo, "BOTTOM", 0, -5)
    titre:SetText("F L O A T I N G  I C O N S")
    titre:SetTextColor(1, 1, 1, 1)
    
    -- Rendre déplaçable
    fenetre:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then
            fenetre:StartMoving()
        end
    end)
    
    fenetre:SetScript("OnMouseUp", function()
        fenetre:StopMovingOrSizing()
    end)
    
    -- Bouton de fermeture
    local boutonFermer = CreateFrame("Button", nil, fenetre, "UIPanelCloseButton")
    boutonFermer:SetPoint("TOPRIGHT", fenetre, "TOPRIGHT", -5, -5)
    
    -- Menu déroulant d'icônes avec pagination - MODIFIÉ POUR SUPPORTER LA PAGINATION
    local menuDeroulant = CreateFrame("Frame", "CustomIconsDropdown", fenetre, "UIDropDownMenuTemplate")
    menuDeroulant:SetPoint("TOPLEFT", fenetre, "TOPLEFT", 15, -80)
    
    UIDropDownMenu_SetWidth(120, menuDeroulant)
    local nombrePages = self:ObtenirNombrePages()
    UIDropDownMenu_SetText("Page 1/" .. nombrePages, menuDeroulant)
    UIDropDownMenu_Initialize(menuDeroulant, self:InitialiserDropdownPagine())
    
    -- Aperçu de l'icône - MODIFIER LA TAILLE/POSITION DE L'APERÇU ICI
    local apercu = CreateFrame("Frame", nil, fenetre)
    apercu:SetWidth(48)
    apercu:SetHeight(48)
    apercu:SetPoint("LEFT", menuDeroulant, "RIGHT", -25, 0)
    
    local textureApercu = apercu:CreateTexture(nil, "ARTWORK")
    textureApercu:SetAllPoints(apercu)
    textureApercu:SetTexture("Interface\\AddOns\\CustomIcons\\icons\\a") -- Aperçu par défaut
    
    -- Curseur d'échelle - MODIFIER LA PLAGE D'ÉCHELLE ICI
    local curseurEchelle = CreateFrame("Slider", "CustomIconsScaleSlider", fenetre, "OptionsSliderTemplate")
    curseurEchelle:SetPoint("TOPLEFT", fenetre, "TOPLEFT", 20, -140)
    curseurEchelle:SetMinMaxValues(0.5, 3.0)
    curseurEchelle:SetValue(1.0)
    curseurEchelle:SetValueStep(0.1)
    
    getglobal(curseurEchelle:GetName() .. "Low"):SetText("0.5")
    getglobal(curseurEchelle:GetName() .. "High"):SetText("3.0")
    getglobal(curseurEchelle:GetName() .. "Text"):SetText("Échelle: 1.0")
    
    curseurEchelle:SetScript("OnValueChanged", function()
        getglobal(this:GetName() .. "Text"):SetText("Échelle: " .. string.format("%.1f", this:GetValue()))
    end)
    
    -- Curseur de transparence - MODIFIER LA PLAGE DE TRANSPARENCE ICI
    local curseurAlpha = CreateFrame("Slider", "CustomIconsAlphaSlider", fenetre, "OptionsSliderTemplate")
    curseurAlpha:SetPoint("TOPLEFT", curseurEchelle, "BOTTOMLEFT", 0, -30)
    curseurAlpha:SetMinMaxValues(0.1, 1.0)
    curseurAlpha:SetValue(1.0)
    curseurAlpha:SetValueStep(0.1)
    
    getglobal(curseurAlpha:GetName() .. "Low"):SetText("0.1")
    getglobal(curseurAlpha:GetName() .. "High"):SetText("1.0")
    getglobal(curseurAlpha:GetName() .. "Text"):SetText("Transparence: 1.0")
    
    curseurAlpha:SetScript("OnValueChanged", function()
        getglobal(this:GetName() .. "Text"):SetText("Transparence: " .. string.format("%.1f", this:GetValue()))
    end)
    
    -- Curseur de bordure - NOUVEAU: Contrôle de la bordure des icônes
    local curseurBordure = CreateFrame("Slider", "CustomIconsBorderSlider", fenetre, "OptionsSliderTemplate")
    curseurBordure:SetPoint("TOPLEFT", curseurAlpha, "BOTTOMLEFT", 0, -30)
    curseurBordure:SetMinMaxValues(0.0, 1.0)
    curseurBordure:SetValue(0.0)
    curseurBordure:SetValueStep(0.1)
    
    getglobal(curseurBordure:GetName() .. "Low"):SetText("0.0")
    getglobal(curseurBordure:GetName() .. "High"):SetText("1.0")
    getglobal(curseurBordure:GetName() .. "Text"):SetText("Bordure: 0.0")
    
    curseurBordure:SetScript("OnValueChanged", function()
        getglobal(this:GetName() .. "Text"):SetText("Bordure: " .. string.format("%.1f", this:GetValue()))
    end)
    
    -- Bouton créer icône flottante
    local boutonCreer = CreateFrame("Button", nil, fenetre, "GameMenuButtonTemplate")
    boutonCreer:SetPoint("TOPLEFT", curseurBordure, "BOTTOMLEFT", 0, -20)
    boutonCreer:SetWidth(100)
    boutonCreer:SetHeight(25)
    boutonCreer:SetText("Créer Icône")
    boutonCreer:SetScript("OnClick", function()
        CustomIcons:CreerIconeFlottante()
    end)
    
    -- Bouton de verrouillage - NOUVEAU: Verrouiller/Déverrouiller les icônes
    local boutonVerrou = CreateFrame("Button", nil, fenetre, "GameMenuButtonTemplate")
    boutonVerrou:SetPoint("LEFT", boutonCreer, "RIGHT", 10, 0)
    boutonVerrou:SetWidth(80)
    boutonVerrou:SetHeight(25)
    boutonVerrou:SetText("Verrouiller")
    boutonVerrou:SetScript("OnClick", function()
        CustomIcons:BasculerVerrouillage()
        CustomIcons:MettreAJourBoutonVerrou(boutonVerrou)
    end)
    
    -- Bouton effacer tout
    local boutonEffacer = CreateFrame("Button", nil, fenetre, "GameMenuButtonTemplate")
    boutonEffacer:SetPoint("LEFT", boutonVerrou, "RIGHT", 10, 0)
    boutonVerrou:SetWidth(60)
    boutonEffacer:SetWidth(60)
    boutonEffacer:SetHeight(25)
    boutonEffacer:SetText("Effacer")
    boutonEffacer:SetScript("OnClick", function()
        CustomIcons:EffacerToutesIcones()
    end)
    
    -- Section des profils - NOUVEAU: Gestion des profils
    local titreProfil = fenetre:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titreProfil:SetPoint("TOPLEFT", boutonCreer, "BOTTOMLEFT", 0, -15)
    titreProfil:SetText("Profils:")
    titreProfil:SetTextColor(1, 1, 0, 1) -- Jaune
    
    -- Bouton sauvegarder profil
    local boutonSauver = CreateFrame("Button", nil, fenetre, "GameMenuButtonTemplate")
    boutonSauver:SetPoint("TOPLEFT", titreProfil, "BOTTOMLEFT", 0, -5)
    boutonSauver:SetWidth(80)
    boutonSauver:SetHeight(20)
    boutonSauver:SetText("Sauver")
    boutonSauver:SetScript("OnClick", function()
        CustomIcons:SauvegarderProfil()
    end)
    
    -- Bouton charger profil
    local boutonCharger = CreateFrame("Button", nil, fenetre, "GameMenuButtonTemplate")
    boutonCharger:SetPoint("LEFT", boutonSauver, "RIGHT", 5, 0)
    boutonCharger:SetWidth(80)
    boutonCharger:SetHeight(20)
    boutonCharger:SetText("Charger")
    boutonCharger:SetScript("OnClick", function()
        CustomIcons:ChargerProfil()
    end)
    
    -- Zone de texte pour nom du profil
    local champNomProfil = CreateFrame("EditBox", nil, fenetre, "InputBoxTemplate")
    champNomProfil:SetPoint("LEFT", boutonCharger, "RIGHT", 10, 0)
    champNomProfil:SetWidth(100)
    champNomProfil:SetHeight(20)
    champNomProfil:SetText("Défaut")
    champNomProfil:SetAutoFocus(false)
    
    -- Liste des icônes - MODIFIER LA TAILLE/POSITION DE LA LISTE ICI
    local cadreDefilement = CreateFrame("ScrollFrame", "CustomIconsScrollFrame", fenetre, "UIPanelScrollFrameTemplate")
    cadreDefilement:SetPoint("TOPLEFT", boutonSauver, "BOTTOMLEFT", 0, -10)
    cadreDefilement:SetPoint("BOTTOMRIGHT", fenetre, "BOTTOMRIGHT", -30, 15)
    
    local cadreListe = CreateFrame("Frame", nil, cadreDefilement)
    cadreListe:SetWidth(cadreDefilement:GetWidth())
    cadreListe:SetHeight(1)
    cadreDefilement:SetScrollChild(cadreListe)
    
    -- Stocker les références
    self.fenetrePrincipale = fenetre
    self.menuDeroulant = menuDeroulant
    self.apercu = textureApercu
    self.curseurEchelle = curseurEchelle
    self.curseurAlpha = curseurAlpha
    self.curseurBordure = curseurBordure
    self.boutonVerrou = boutonVerrou
    self.champNomProfil = champNomProfil
    self.cadreListe = cadreListe
    
    self:MettreAJourListeIcones()
    self:MettreAJourBoutonVerrou(boutonVerrou)
end

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================

-- Mettre à jour l'aperçu de l'icône
function CustomIcons:MettreAJourApercu(nomIcone)
    if self.apercu and nomIcone then
        local cheminTexture = "Interface\\AddOns\\CustomIcons\\icons\\" .. nomIcone
        self.apercu:SetTexture(cheminTexture)
        -- Si l'aperçu échoue, essayer avec l'extension .tga
        if not self.apercu:GetTexture() then
            self.apercu:SetTexture("Interface\\AddOns\\CustomIcons\\icons\\" .. nomIcone .. ".tga")
        end
    end
end

-- Basculer le verrouillage des icônes - NOUVEAU
function CustomIcons:BasculerVerrouillage()
    self.verrouillee = not self.verrouillee
    CustomIconsDB.verrouillee = self.verrouillee
    
    -- Appliquer le verrouillage à toutes les icônes existantes
    for _, donneesIcone in ipairs(self.iconesFlottantes) do
        if self.verrouillee then
            donneesIcone.cadre:SetMovable(false)
            donneesIcone.cadre:EnableMouse(false)
        else
            donneesIcone.cadre:SetMovable(true)
            donneesIcone.cadre:EnableMouse(true)
        end
    end
    
    local statut = self.verrouillee and "verrouillées" or "déverrouillées"
    DEFAULT_CHAT_FRAME:AddMessage("Icônes " .. statut .. "!")
end

-- Mettre à jour le bouton de verrouillage
function CustomIcons:MettreAJourBoutonVerrou(bouton)
    if self.verrouillee then
        bouton:SetText("Déverrouiller")
    else
        bouton:SetText("Verrouiller")
    end
end

-- ========================================
-- CRÉATION ET GESTION DES ICÔNES
-- ========================================

-- Créer une icône flottante - FONCTION PRINCIPALE DE CRÉATION D'ICÔNE
function CustomIcons:CreerIconeFlottante()
    local iconeSelectionnee = UIDropDownMenu_GetSelectedValue(self.menuDeroulant)
    if not iconeSelectionnee or iconeSelectionnee == "" or iconeSelectionnee == "PREV_PAGE" or iconeSelectionnee == "NEXT_PAGE" or iconeSelectionnee == "PAGE_INFO" then
        DEFAULT_CHAT_FRAME:AddMessage("Veuillez d'abord sélectionner une icône valide!")
        return
    end
    
    local echelle = self.curseurEchelle:GetValue()
    local alpha = self.curseurAlpha:GetValue()
    local bordure = self.curseurBordure:GetValue()
    
    -- Créer le cadre de l'icône - MODIFIER LES PROPRIÉTÉS DE L'ICÔNE ICI
    local icone = CreateFrame("Frame", nil, UIParent)
    icone:SetWidth(32 * echelle)
    icone:SetHeight(32 * echelle)
    icone:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    icone:SetFrameStrata("TOOLTIP") -- Au-dessus de tout, y compris les barres d'action
    icone:SetMovable(true)
    icone:EnableMouse(true)
    
    -- Bordure optionnelle - NOUVEAU
    if bordure > 0 then
        icone:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        icone:SetBackdropBorderColor(1, 1, 1, bordure)
    end
    
    -- Texture de l'icône
    local texture = icone:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(icone)
    local cheminTexture = "Interface\\AddOns\\CustomIcons\\icons\\" .. iconeSelectionnee
    texture:SetTexture(cheminTexture)
    texture:SetAlpha(alpha)
    
    -- Vérifier si la texture s'est chargée
    if not texture:GetTexture() then
        -- Essayer avec l'extension .tga
        local cheminAlt = "Interface\\AddOns\\CustomIcons\\icons\\" .. iconeSelectionnee .. ".tga"
        texture:SetTexture(cheminAlt)
        
        if not texture:GetTexture() then
            -- Utiliser une icône de secours
            texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            DEFAULT_CHAT_FRAME:AddMessage("ATTENTION: Impossible de charger " .. iconeSelectionnee .. ".tga")
        end
    end
    
    -- Rendre déplaçable (si pas verrouillé)
    if not self.verrouillee then
        icone:SetScript("OnMouseDown", function()
            if arg1 == "LeftButton" then
                icone:StartMoving()
            elseif arg1 == "RightButton" then
                -- Clic droit pour supprimer - MODIFIER LE COMPORTEMENT DE SUPPRESSION ICI
                CustomIcons:SupprimerIconeFlottante(icone)
            end
        end)
        
        icone:SetScript("OnMouseUp", function()
            icone:StopMovingOrSizing()
            CustomIcons:SauvegarderPositionIcone(icone)
        end)
    else
        icone:SetMovable(false)
        icone:EnableMouse(false)
    end
    
    -- Stocker les données de l'icône
    local donneesIcone = {
        cadre = icone,
        icone = iconeSelectionnee,
        echelle = echelle,
        alpha = alpha,
        bordure = bordure,
        x = 0,
        y = 0
    }
    
    table.insert(self.iconesFlottantes, donneesIcone)
    table.insert(CustomIconsDB.icones, {
        icone = iconeSelectionnee,
        echelle = echelle,
        alpha = alpha,
        bordure = bordure,
        x = 0,
        y = 0
    })
    
    self:MettreAJourListeIcones()
    DEFAULT_CHAT_FRAME:AddMessage("Icône flottante créée! Clic droit pour supprimer.")
end

-- Supprimer une icône flottante
function CustomIcons:SupprimerIconeFlottante(cadre)
    for i, donneesIcone in ipairs(self.iconesFlottantes) do
        if donneesIcone.cadre == cadre then
            cadre:Hide()
            cadre = nil
            table.remove(self.iconesFlottantes, i)
            table.remove(CustomIconsDB.icones, i)
            break
        end
    end
    self:MettreAJourListeIcones()
end

-- Effacer toutes les icônes - NOUVEAU
function CustomIcons:EffacerToutesIcones()
    for _, donneesIcone in ipairs(self.iconesFlottantes) do
        donneesIcone.cadre:Hide()
        donneesIcone.cadre = nil
    end
    
    self.iconesFlottantes = {}
    CustomIconsDB.icones = {}
    self:MettreAJourListeIcones()
    DEFAULT_CHAT_FRAME:AddMessage("Toutes les icônes ont été effacées!")
end

-- Sauvegarder la position d'une icône
function CustomIcons:SauvegarderPositionIcone(cadre)
    for i, donneesIcone in ipairs(self.iconesFlottantes) do
        if donneesIcone.cadre == cadre then
            local x, y = cadre:GetCenter()
            donneesIcone.x = x
            donneesIcone.y = y
            CustomIconsDB.icones[i].x = x
            CustomIconsDB.icones[i].y = y
            break
        end
    end
end

-- ========================================
-- GESTION DES PROFILS - NOUVEAU
-- ========================================

-- Sauvegarder un profil
function CustomIcons:SauvegarderProfil()
    local nomProfil = self.champNomProfil:GetText()
    if nomProfil == "" then
        nomProfil = "Défaut"
    end
    
    if not CustomIconsDB.profils then
        CustomIconsDB.profils = {}
    end
    
    -- Copier les données actuelles
    CustomIconsDB.profils[nomProfil] = {
        icones = {},
        verrouillee = self.verrouillee
    }
    
    for _, donneesIcone in ipairs(CustomIconsDB.icones) do
        table.insert(CustomIconsDB.profils[nomProfil].icones, {
            icone = donneesIcone.icone,
            echelle = donneesIcone.echelle,
            alpha = donneesIcone.alpha,
            bordure = donneesIcone.bordure,
            x = donneesIcone.x,
            y = donneesIcone.y
        })
    end
    
    CustomIconsDB.profilActuel = nomProfil
    DEFAULT_CHAT_FRAME:AddMessage("Profil '" .. nomProfil .. "' sauvegardé!")
end

-- Charger un profil
function CustomIcons:ChargerProfil()
    local nomProfil = self.champNomProfil:GetText()
    if nomProfil == "" then
        nomProfil = "Défaut"
    end
    
    if not CustomIconsDB.profils or not CustomIconsDB.profils[nomProfil] then
        DEFAULT_CHAT_FRAME:AddMessage("Profil '" .. nomProfil .. "' non trouvé!")
        return
    end
    
    -- Effacer les icônes actuelles
    self:EffacerToutesIcones()
    
    -- Charger les données du profil
    local profil = CustomIconsDB.profils[nomProfil]
    CustomIconsDB.icones = profil.icones
    CustomIconsDB.verrouillee = profil.verrouillee
    CustomIconsDB.profilActuel = nomProfil
    
    -- Restaurer les icônes
    self:RestaurerIcones()
    
    -- Mettre à jour l'état de verrouillage
    self.verrouillee = profil.verrouillee
    if self.boutonVerrou then
        self:MettreAJourBoutonVerrou(self.boutonVerrou)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Profil '" .. nomProfil .. "' chargé!")
end

-- ========================================
-- RESTAURATION DES ICÔNES SAUVEGARDÉES
-- ========================================

-- Restaurer les icônes sauvegardées
function CustomIcons:RestaurerIcones()
    -- Restaurer les icônes flottantes
    if CustomIconsDB.icones then
        for _, donneesIcone in ipairs(CustomIconsDB.icones) do
            local icone = CreateFrame("Frame", nil, UIParent)
            icone:SetWidth(32 * donneesIcone.echelle)
            icone:SetHeight(32 * donneesIcone.echelle)
            icone:SetFrameStrata("TOOLTIP")
            icone:SetMovable(true)
            icone:EnableMouse(true)
            
            if donneesIcone.x and donneesIcone.y then
                icone:SetPoint("CENTER", UIParent, "BOTTOMLEFT", donneesIcone.x, donneesIcone.y)
            else
                icone:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
            
            -- Bordure optionnelle
            if donneesIcone.bordure and donneesIcone.bordure > 0 then
                icone:SetBackdrop({
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                icone:SetBackdropBorderColor(1, 1, 1, donneesIcone.bordure)
            end
            
            local texture = icone:CreateTexture(nil, "ARTWORK")
            texture:SetAllPoints(icone)
            texture:SetTexture("Interface\\AddOns\\CustomIcons\\icons\\" .. donneesIcone.icone)
            texture:SetAlpha(donneesIcone.alpha)
            
            -- Scripts de souris (si pas verrouillé)
            if not self.verrouillee then
                icone:SetScript("OnMouseDown", function()
                    if arg1 == "LeftButton" then
                        icone:StartMoving()
                    elseif arg1 == "RightButton" then
                        CustomIcons:SupprimerIconeFlottante(icone)
                    end
                end)
                
                icone:SetScript("OnMouseUp", function()
                    icone:StopMovingOrSizing()
                    CustomIcons:SauvegarderPositionIcone(icone)
                end)
            else
                icone:SetMovable(false)
                icone:EnableMouse(false)
            end
            
            table.insert(self.iconesFlottantes, {
                cadre = icone,
                icone = donneesIcone.icone,
                echelle = donneesIcone.echelle,
                alpha = donneesIcone.alpha,
                bordure = donneesIcone.bordure or 0,
                x = donneesIcone.x,
                y = donneesIcone.y
            })
        end
    end
    
    -- Restaurer l'état de verrouillage
    if CustomIconsDB.verrouillee then
        self.verrouillee = CustomIconsDB.verrouillee
    end
end

-- ========================================
-- INTERFACE UTILISATEUR - MISE À JOUR
-- ========================================

-- Mettre à jour la liste des icônes affichées
function CustomIcons:MettreAJourListeIcones()
    if not self.cadreListe then return end
    
    -- Effacer les éléments existants de la liste
    local enfants = {self.cadreListe:GetChildren()}
    for _, enfant in ipairs(enfants) do
        enfant:Hide()
        enfant = nil
    end
    
    local decalageY = 0
    
    -- Ajouter les icônes flottantes à la liste
    for i, donneesIcone in ipairs(self.iconesFlottantes) do
        local element = CreateFrame("Frame", nil, self.cadreListe)
        element:SetWidth(self.cadreListe:GetWidth() - 20)
        element:SetHeight(18)
        element:SetPoint("TOPLEFT", self.cadreListe, "TOPLEFT", 10, -decalageY)
        
        local texte = element:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        texte:SetPoint("LEFT", element, "LEFT", 0, 0)
        local info = string.format("Icône: %s (É: %.1f, T: %.1f, B: %.1f)", 
            donneesIcone.icone, donneesIcone.echelle, donneesIcone.alpha, donneesIcone.bordure or 0)
        texte:SetText(info)
        texte:SetTextColor(1, 1, 1, 1)
        
        decalageY = decalageY + 22
    end
    
    -- Afficher le statut de verrouillage
    if table.getn(self.iconesFlottantes) > 0 then
        local elementStatut = CreateFrame("Frame", nil, self.cadreListe)
        elementStatut:SetWidth(self.cadreListe:GetWidth() - 20)
        elementStatut:SetHeight(18)
        elementStatut:SetPoint("TOPLEFT", self.cadreListe, "TOPLEFT", 10, -decalageY)
        
        local texteStatut = elementStatut:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        texteStatut:SetPoint("LEFT", elementStatut, "LEFT", 0, 0)
        local statut = self.verrouillee and "VERROUILLÉES" or "DÉVERROUILLÉES"
        texteStatut:SetText("Statut: " .. statut)
        texteStatut:SetTextColor(self.verrouillee and 1 or 0, self.verrouillee and 0 or 1, 0, 1)
        
        decalageY = decalageY + 22
    end
    
    self.cadreListe:SetHeight(math.max(decalageY, 1))
end

-- Basculer la fenêtre principale
function CustomIcons:BasculerFenetrePrincipale()
    if not self.fenetrePrincipale then
        self:CreerFenetrePrincipale()
    end
    
    -- Always ensure frame exists before trying to show/hide
    if self.fenetrePrincipale then
        if self.fenetrePrincipale:IsVisible() then
            self.fenetrePrincipale:Hide()
        else
            self.fenetrePrincipale:Show()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Erreur: Impossible de créer la fenêtre!")
    end
end

-- ========================================
-- INITIALISATION FINALE
-- ========================================

-- Créer le cadre d'événement principal
local cadreEvenement = CreateFrame("Frame")
cadreEvenement:SetScript("OnEvent", function() CustomIcons:SurEvenement() end)

-- Initialiser l'addon
CustomIcons:AuChargement(cadreEvenement)

-- Message de chargement - MODIFIER LE MESSAGE DE CHARGEMENT ICI
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Custom Icons Enhanced|r chargé! Tapez |cffffcc00/cic|r pour ouvrir.")