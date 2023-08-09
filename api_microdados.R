pacman::p_load(tidyverse, # caixa de ferramentas 
               bigrquery, # Para acessar o query do google
               plotly
               
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

microdados_tbl <- tbl(conexao,"microdados_vinculos") %>% 
  select( everything() ) %>% 
  filter( 
    ano >= 2013 ,sigla_uf == "CE"
  )

# Base de dados
tbl_rais_ce <- microdados_tbl |> collect()
tbl_rais_ce <- read.csv("rais_ce.csv")
#Nomes dos bairros
nomes_rais_ce <- read.csv2("Bairros_fortaleza_rais.csv")
# Colocando o nome dos bairros juntos
tbl_rais_ce <- left_join(tbl_2021,nomes_rais_ce,by = "bairros_fortaleza")

# 

tbl_2021 <- tbl_rais_ce |> 
  filter(ano == 2021) |> 
  select(ano,sigla_uf,bairros_fortaleza)

left_join(tbl_2021,nomes_rais_ce,by = "bairros_fortaleza")
