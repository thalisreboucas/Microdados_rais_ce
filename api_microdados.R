pacman::p_load(tidyverse, # caixa de ferramentas 
               bigrquery, # Para acessar o query do google
               plotly,
               basededados
               
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
remove(conexao,
       microdados_tbl_estabelecimento,
       Aux_rais,tp,te,ss)


tbl_usar <- tbl_ce_estabelecimento |> select(ano,Tipo_est,
                                 Funcionario_empresa,
                                 quantidade_vinculos_ativos,
                                 cnae_1,cnae_2,
                                 cep,Bairros,Subsetor)

tbl_usar <- ceps_nomes |> mutate(cep = as.character(Cep) ) |>left_join(tbl_usar,ceps_nomes,by = "cep")


remove(ceps_nomes,tbl_ce_estabelecimento,ceps)

restaurantes =c("5611201", "5620101", "5620104")
supermercados = c("4711301","4711302", "4712100")
atacado = c("4639701", "4639702")

tbl_usar |> mutate( setor =case_when(cnae_1 %in% restaurantes ~"restaurante",
                                     cnae_2 %in% restaurantes ~"restaurante",
                                     cnae_1 %in% supermercados ~"supermercados",
                                     cnae_2 %in% supermercados ~"supermercados",
                                     cnae_1 %in% atacado ~"atacado",
                                     cnae_2 %in% atacado ~"atacado")) |>  view()
