# USER ROLES
{ :admin => %w(),
  :editor => %w(),
  :topic_editor => %w()
}.each_pair { |role, users| users.each { |user| user.has_role!(role) } }

# TOPIC CATEGORIES
#%w(#echonomyjam #echocracy #echo #echosocial #realprices #igf #klimaherbsttv).each { |name| Tag.create(:value => name) }


###############
#  ENUM KEYS  #
###############

# LANGUAGES
Language.enumeration_model_updates_permitted = true
Language.purge_enumerations_cache
%w(en de fr pt es hu).each_with_index do |code, index|
  Language.create(:code => code, :key => index+1, :description => "language")
end
Language.enumeration_model_updates_permitted = false

# LANGUAGE LEVELS
LanguageLevel.enumeration_model_updates_permitted = true
LanguageLevel.purge_enumerations_cache
%w(mother_tongue advanced intermediate basic).each_with_index do |code, index|
  LanguageLevel.create(:code => code, :key => index+1, :description => "language_level")
end
LanguageLevel.enumeration_model_updates_permitted = false

# WEB ADDRESSES
WebAddressType.enumeration_model_updates_permitted = true
WebAddressType.purge_enumerations_cache
%w(email homepage blog xing linkedin facebook twitter).each_with_index do |code, index|
  WebAddressType.create(:code => code, :key => index+1, :description => "web_address_type")
end
WebAddressType.create(:code => 'other', :key => 99, :description => "web_address_type")
WebAddressType.enumeration_model_updates_permitted = false

# ORGANISATION TYPES
OrganisationType.enumeration_model_updates_permitted = true
OrganisationType.purge_enumerations_cache
%w(ngo political scientific trade_union social_business profit_driven_business).each_with_index do |code, index|
  OrganisationType.create(:code => code, :key => index+1, :description => "organisation_type")
end
OrganisationType.enumeration_model_updates_permitted = false

# TAG CONTEXTS
TagContext.enumeration_model_updates_permitted = true
TagContext.purge_enumerations_cache
%w(affection engagement expertise decision_making field_work field_activity topic).each_with_index do |code, index|
  TagContext.create(:code => code, :key => index+1, :description => "tag_context")
end
TagContext.enumeration_model_updates_permitted = false

# STATEMENT STATES
StatementState.enumeration_model_updates_permitted = true
StatementState.purge_enumerations_cache
%w(new published).each_with_index do |code, index|
  StatementState.create(:code => code, :key => index+1, :description => "statement_state")
end
StatementState.enumeration_model_updates_permitted = false

# STATEMENT DOCUMENT ACTIONS
StatementAction.enumeration_model_updates_permitted = true
StatementAction.purge_enumerations_cache
%w(created updated translated incorporated).each_with_index do |code, index|
  StatementAction.create(:code => code, :key => index+1, :description => "statement_action")
end
StatementAction.enumeration_model_updates_permitted = false

# ABOUT CATEGORIES
AboutCategory.enumeration_model_updates_permitted = true
AboutCategory.purge_enumerations_cache
%w(core_team supporters translators interns alumni technology_partners financial_partners strategic_partners thematic_partners partners).each_with_index do |code, index|
  AboutCategory.create(:code => code, :key => index+1, :description => "about_category")
end
AboutCategory.enumeration_model_updates_permitted = false

# INFO TYPE
InfoType.enumeration_model_updates_permitted = true
InfoType.purge_enumerations_cache
%w(article paper book audio photo video law document misc).each_with_index do |code, index|
  InfoType.create(:code => code, :key => index+1, :description => "info_type")
end
InfoType.enumeration_model_updates_permitted = false

#################
#  ENUM VALUES  #
#################

EnumValue.enumeration_model_updates_permitted = true
EnumValue.purge_enumerations_cache

# Languages
# Order of values: EN, DE, FR, PT, ES, HU
["English","Englisch","Ingles","Inglês","Inglés","Angol"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('en'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context => "")
end
["German","Deutsch","Aleman","Alemão","Alemán","Német"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('de'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context => "")
end
["French","Französisch","Français","Francês","Francés","Francia"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('fr'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context => "")
end
["Portuguese","Portugiesisch","Portugais","Português","Portugués","Portugál"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('pt'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context => "")
end
["Spanish","Spanisch","Espagnol","Espanhol","Español","Spanyol"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('es'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context => "")
end
["Hungarian","Ungarisch","Hongrois","Húngaro","Húngaro","Magyar"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('hu'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context => "")
end

# Language Levels
# Order of values: EN, DE, FR, PT, ES, HU
["Mother Tongue","Muttersprache","Langue Maternelle","Língua Materna","Lengua Materna","Anyanyelv"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('mother_tongue'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context=> "")
end
["Advanced","Fortgeschritten","Avancé","Avançado","Avanzado","Felsőfok"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('advanced'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context=> "")
end
["Intermediate","Mittelstufe","Intermédiaire","Intermédio","Intermedio","Középfok"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('intermediate'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context=> "")
end
["Basic","Grundkenntnisse","Basique","Básico","Basico","Alapfok"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('basic'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context=> "")
end

# Web Addresses
# Order of values: EN, DE, FR, PT, ES, HU
Language.all.length.times do |index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('email'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "E-mail", :context=> "")
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('homepage'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "Homepage", :context=> "")
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('blog'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "Blog", :context=> "")
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('xing'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "Xing", :context=> "")
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('linkedin'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "LinkedIn", :context=> "")
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('facebook'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "Facebook", :context=> "")
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('twitter'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => "Twitter", :context=> "")
end
["Other","Andere","Autre","Outro","Otro","Egyéb"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('other'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context=> "")
end

# Organization Types
# Order of values: EN, DE, FR, PT, ES, HU
["NGO","NRO","ONG","ONG","ONG","Civil Szervezet"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('ngo'),
                              :code => EnumKey.find_by_type_and_key('Language', index+1).code,
                              :value => value, :context=> "")
end
["Political","Politisch","Politique","Política","Política","Politikai"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('political'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Scientific","Wissenschaftlich","Scientifique","Científica","Científica","Tudományos"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('scientific'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Trade Union","Gewerkschaft","Syndicat","Sindicato","Sindicato","Szakszervezet"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('trade_union'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Social Business","Social Business","Social Business","Social Business","Social Business", "Social Business"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('social_business'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Profit-Driven Business","Gewinnorientierte Firma","Firma à but lucratif",
 "Firma com fins lucrativos","Firma de lucro","Profitorientált Cég"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('profit_driven_business'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end

# Tag Contexts
# Order of values: EN, DE, FR, PT, ES, HU
["Affection","Betroffenheit","Affection","Afeição","Afecto","Érintettség"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('affection'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Engagement","Engagement","Engagement","Compromisso","Compromisso","Aktivitás"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('engagement'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Expertise","Expertise","Expertise","Especialidade","Peritaje","Szaktudás"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('expertise'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Decision Making","Entscheidung","Décision","Decisão","Decisión","Döntéshozás"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('decision_making'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Field of Work","Arbeitsfeld","Domaine de travail",
 "Domínio de Trabalho","Área de Trabajo","Munkaterület"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('field_work'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Field of Activity","Betätigungsfeld","Domaine d'activité",
 "Domínio de Actividade","Área de Actividad","Aktivitási Terület"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('field_activity'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Topic","Thema","Sujet","Tópico","Tema","Téma"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code('topic'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end

# Statement States
# Order of values: EN, DE, FR, PT, ES, HU
["New","Neu","Neuf","Novo","Nuevo","Új"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('new','StatementState'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Published","Veröffentlicht","Publié","Publicado","Publicado","Publikált"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('published','StatementState'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end

# Statement Actions
# Order of values: EN, DE, FR, PT, ES, HU
["New","Neu","Neuf","Novo","Nuevo","Új"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('created','StatementAction'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Edit","Editieren","Éditer","Editar","Editar","Szerkesztem"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('updated','StatementAction'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Translate","Übersetzen","Traduire","Traduzir","Traducir","Lefordítom"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('translated','StatementAction'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Incorporate","Einfügen","Incorporer","Incorporar","Incorporar","Összefésülöm"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('incorporated','StatementAction'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end


# About Items
# Order of values: EN, DE, FR, PT, ES, HU
["Core Team","Kernteam","Coeur équipe","Equipa-Núcleo","Equipo Núcleo","Belső Csapat"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('core_team','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["External Staff & Supporters","Externe Mitarbeiter & Unterstützer","Personnel Externe & Collaborateurs",
 "Pessoal Externo & Colaboradores","Personal Externo & Colaboradores","Külsősök & Támogatók"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('supporters','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Translators","Übersetzer","Traducteurs","Tradutores","Traductores","Fordítók"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('translators','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Interns","Praktikanten","Stagiaires","Estagiários","Becarios","Gyakornokok"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('interns','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Alumni","Alumni","Alumni","Alumni","Alumni","Alumni"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('alumni','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end

["Partners","Partner","Les partenaires", "Parceiros","Socios","Partnerek"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('partners','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Technology Partners","Technologiepartner","Les partenaires tecnologiques",
 "Parceiros Tecnológicos","Socios Técnicos","Technológiai Partnerek"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('technology_partners','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Financial Partners","Finanzpartner","Les partenaires financières",
 "Parceiros Financeiros","Socios Financieros","Pénzügyi Partnerek"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('financial_partners','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Strategic Partners","Strategische Partner","Les partenaires stratégiques",
 "Parceiros Estratégicos","Socios Estratégicos","Stratégiai Partnerek"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('strategic_partners','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Thematic Partners","Thematische Partner","Les partenaires thématiques",
 "Parceiros Temáticos","Socios Temáticos","Tematikus Partnerek"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('thematic_partners','AboutCategory'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end

# Order of values: EN, DE, FR, PT, ES, HU
["Article","Artikel","Article","Artigo","Artículo","Cikk"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('article','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Paper","Ausarbeitung","Art. Scientifique","Artigo Científico","Artículo Científico","Tudományos cikk"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('paper','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Book","Buch","Livre","Livro","Libro","Könyv"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('book','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Audio","Audio","Audio","Audio","Audio","Hanganyag"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('audio','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Photo","Foto","Photo","Fotografia","Foto","Fénykép"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('photo','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Video","Video","Vidéo","Video","Vídeo","Videó"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('video','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Law","Rechtliches","Loi","Legislação","Ley","Jogszabály"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('law','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Document","Dokument","Document","Documento","Documento","Dokumentum"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('document','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end
["Other","Sonstiges","Divers","Outro","Otro","Egyéb"].each_with_index do |value,index|
  EnumValue.create_or_update!(:enum_key => EnumKey.find_by_code_and_type('misc','InfoType'),
                              :code => EnumKey.find_by_type_and_key('Language',index+1).code,
                              :value => value, :context=> "")
end

EnumValue.enumeration_model_updates_permitted = false