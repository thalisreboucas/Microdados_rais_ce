pacman::p_load(tidyverse, # caixa de ferramentas 
               bigrquery, # Para acessar o query do google
               plotly,
               leaflet,
               geobr,
               leaflet.extras,
               sf,
               viridis
)

# base de dados 

conexao <- dbConnect( 
  bigquery(),
  project = "basedosdados",
  dataset = "br_me_rais" ,
  billing = "black-overview-334521"
  #dataset = "br_me_caged",
  #dataset = "br_me_cpnj"
)

microdados_tbl_vinculo <- tbl(conexao,"microdados_vinculos") %>% 
  select( everything() ) %>% 
  filter( 
    ano >= 2020 ,sigla_uf == "CE"
  )

microdados_tbl_estabelecimento <- tbl(conexao,"microdados_estabelecimentos") %>% 
  select( everything() ) %>% 
  filter( 
    ano >= 2021 ,sigla_uf == "CE"
  )

# Base de dados
tbl_ce_estabelecimento <- microdados_tbl_estabelecimento |> collect()
saveRDS(tbl_ce_estabelecimento,"tbl_ce_estabelecimento")

# Chamar a base
tbl_ce_estabelecimento <- readRDS("tbl_ce_estabelecimento")
#Nomes dos bairros
Aux_rais <- readxl::read_excel("Aux_rais.xlsx", sheet = "Bairros")
te <- readxl::read_excel("Aux_rais.xlsx", sheet = "Tamanho_estabelecimento") 
tp <- readxl::read_excel("Aux_rais.xlsx", sheet = "Tipo_estb")
ss <- readxl::read_excel("Aux_rais.xlsx", sheet = "subsetor")

ceps_nomes <- readxl::read_excel("Cep_Ce.xlsx")
# Colocando o nome dos bairros juntos
# 
tbl_ce_estabelecimento <- left_join(tbl_ce_estabelecimento,
                                    Aux_rais,by = "bairros_fortaleza") 
tbl_ce_estabelecimento <- te |> mutate(tamanho = as.character(tamanho) ) |> 
                                left_join(tbl_ce_estabelecimento,
                                    .,by = "tamanho")
tbl_ce_estabelecimento <- tp |> mutate(tipo = as.character(tipo) ) |>
                            left_join(tbl_ce_estabelecimento,
                                  tp,by = "tipo") 
tbl_ce_estabelecimento <- left_join(tbl_ce_estabelecimento,
                                  ss,by = "subsetor_ibge")

tbl_ce_estabelecimento <- ceps_nomes |> mutate(cep = as.character(Cep) ) |>left_join(tbl_ce_estabelecimento,ceps_nomes,by = "cep")



remove(ceps_nomes,ceps)
remove(conexao,
       microdados_tbl_estabelecimento,
       Aux_rais,tp,te,ss)


tbl_usar <- tbl_ce_estabelecimento |> select(ano,Tipo_est,
                                 Funcionario_empresa,
                                 quantidade_vinculos_ativos,
                                 cnae_2_subclasse,
                                 cep,Subsetor,Rua,Bairro)


saveRDS(tbl_usar,"tbl_usar")
tbl_usar <- readRDS("tbl_usar")

restaurantes =c("5611201", "5620101", "5620104")
supermercados = c("4711301","4711302", "4712100")
atacado = c("4639701", "4639702")

tbl_cnae <- tbl_usar |> mutate( setor =case_when( cnae_2_subclasse %in% restaurantes ~"restaurante",
                                      cnae_2_subclasse %in% supermercados ~"supermercados",
                                     cnae_2_subclasse %in% atacado ~"atacado")) 

tbl_cnae <- tbl_cnae |>  filter(setor %in% c("restaurantes","supermercados","atacado")) |> select(-Bairros) 

remove(tbl_usar,atacado,restaurantes,supermercados,tbl_ce_estabelecimento,tbl_cnae)

saveRDS(tbl_cnae,"tabela_cnae")
tbl <- readRDS("tabela_cnae")


total <- tbl |> dplyr::group_by(setor,Bairro) |>  
                summarise(total = n()) |>  
                 mutate(name_neighborhood = Bairro) |>  select(-Bairro)

ceara <- geobr::read_neighborhood() |> filter(abbrev_state == "CE"#,
                                                  #name_muni = "Fortaleza")
)



locais <- ceara |>  filter(name_muni =="Fortaleza" , name_neighborhood %in% total$name_neighborhood) |>  select(name_neighborhood,geom)  

esse <- left_join(ceara,total,by = "name_neighborhood") |>  filter(setor == "atacado")

bins <- c(0, 5, 10,15,20, 50, 100, 200)
pal <- colorNumeric(palette = "magma", domain = esse$total,bins)

leaflet() |> 
  addTiles() |> 
  addPolygons(
    data = esse$geocm,
    color = pal(esse$total),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7,
    highlightOptions = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE),
    label = paste(esse$name_district,esse$total),
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "15px",
      direction = "auto")) |> 
  addLegend(pal = pal, values = ~esse$total, opacity = 0.7, title = NULL,
           position = "bottomright")


