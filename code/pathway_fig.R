#heatmap of proteins of interest

setwd("~/Documents/coverage")
source("code/utils.R")
library(tidyverse)
library(RColorBrewer)
library(svglite)
options(repr.plot.width=20, repr.plot.height=40)
theme_set(theme_minimal(base_size = 23))

# 1. load mag info

mtg_info<-read.delim("analysis/03_metagenome_reanalysis/all_metagenome_reanalysis.txt")
mags_role<-read.delim("analysis/05_MAGs/tables/MAG_confirmed_roles_bwa.txt")
annotated_mags<-read.delim("analysis/07_annotate_MAGs/mag_list.txt",header=F,col.names = "Genome")
mags_role$bac_genus <- sapply(mags_role$bat_bacteria, gtdb_get_clade, clade="g")
mags_role$bac_family <- sapply(mags_role$bat_bacteria, gtdb_get_clade, clade="f")
mags_role$bac_order <- sapply(mags_role$bat_bacteria, gtdb_get_clade, clade="o")
mags_role<-mags_role %>%mutate(bac_genus2=ifelse(bac_genus=="Unknown",paste(bac_family," gen. sp.",sep=""),bac_genus))

annotated_mags<-annotated_mags %>% left_join(mags_role %>% select(Genome, bac_genus2,bac_family,bac_order) %>% distinct())
annotated_mags_arranged<-annotated_mags %>% 
  group_by(bac_family) %>%
  arrange(bac_genus2, .by_group=T)
#remove non-complete mags added out of curiosity
annotated_mags_arranged<- annotated_mags_arranged %>% filter(Genome!="public_SRR14722130_metawrap_bin.2" & Genome!="private_T1889_metawrap_bin.7")

#2. kegg annotations
###load data from Carmen
kegg_of_interest<-read.delim("analysis/07_annotate_MAGs/kegg_of_interest_fig.txt")
kegg_combined<-read.delim("analysis/07_annotate_MAGs/summarized_outputs/carmen_kegg_combined.txt")
colnames(kegg_combined)<-c("locustag","KO","Genome")

###prepare dataset
kegg_list<-kegg_of_interest[,1]

kegg_df <- kegg_combined %>% filter(KO %in% kegg_list) %>% group_by(Genome,KO) %>%
  summarize(sum=n()) %>% mutate(presence=ifelse(sum>0,1,0)) %>% dplyr::select(-sum) %>%
  pivot_wider(names_from = KO,values_from = presence,values_fill = 0) %>%
#new variable: calvin cycle
    #mutate(Calvin_cycle = ifelse(K00855==1 & K01601 == 1 & K01602 ==1 & K00927 == 1 &
     #        K00134==1 & (K01623==1 | K01624==1) & K00615 ==1 & K03841 ==1 &
      #         (K01807==1 | K01808==1),1,0)) %>%
  #new variable: anoxygenic photosystem II
  #mutate(photosystem = ifelse(K08928==1 & K08929==1 & K13991==1 & K13992==1 &
   #                             K08926==1 & K08927==1,1,0)) %>%
  #new variable: bacteriochlorophyll
  mutate(bacteriochlorophyll = ifelse(K04035==1 & K04037==1 & K04038==1 & K04039==1 &
         K11333==1 & K11334==1 & K11335==1 & K11336==1 & K11337==1 & K04040==1 & K10960==1,1,
        ifelse(K04035==1 & K04037==1 & K04038==1 & K04039==1 &
                  K11334==1 & K11335==1 & K11336==1 & K11337==1 & K04040==1 & K10960==1,0.909,0))) %>%
  #new variable: nitrogen fixation
  mutate(nitrogen_fixation = ifelse(K02588==1,1,0)) %>%
  #new variable: Cobalamin
#  mutate(cobalamin = ifelse((K00768==1 & K02226==1) | 
   #      (K02232==1 & K02231==1 & (K02227==1 | K02225==1) & (K00798==1 | K19221==1) ),
   #  1,ifelse(K02232==1 & K02231==1  & (K00798==1 | K19221==1),0.9,0)
   #  )) %>%
  #new variable: biotin
 # mutate(biotin = ifelse(K00652+K00833+K01935+K01012==4,1,
 #                        ifelse(K00652+K00833+K01935+K01012==3,0.75,0))) %>%
  #new variable: Riboflavin
 # mutate(riboflavin = ifelse((K00794==1 & K00793==1 & K11753==1) |
 #        ((K01497==1 | K14652==1) & K11752==1 & K21064==1),1,0)) %>%
  #new variable: thiamin
 # mutate(thiamine = ifelse(K00878==1 & K00941==1 & K00788==1,1,0)) %>%
  #new variable: sorbitol/mannitol transporter
  mutate(sorbitol_mannitol_transporter = ifelse(K10227==1 & 
         K10228==1 & K10229==1 & K10111==1,1,0)) %>%
  #new variable: urea transporter
  mutate(urea_transporter = ifelse(K11959==1 &
                                   K11960==1 &
                                   K11961==1 &
                                   K11962==1 &
                                   K11963==1,1,0)) %>%
  #new variable: Erythritol transporter
  mutate(erythritol_transporter = ifelse(K17202==1 &
                                         K17203==1 &
                                         K17204==1,1,0)) %>%
  #new variable: xylitol transporter
  mutate(xylitol_transporter = ifelse(K17205==1 &
                                      K17206==1 &
                                      K17207==1,1,0)) %>%
  #new variable: Inositol  transporter
  mutate(inositol_transporter = ifelse(K17208==1 &
                                       K17209==1 &
                                       K17210==1,1,0)) %>%
  
  #new variable: glycerol  transporter
  mutate(glycerol_transporter = ifelse(K17321==1 &
                                       K17322==1 &
                                       K17323==1 &
                                       K17324==1 &
                                       K17325==1,1,0)) %>%
  #new variable: urease
  mutate(urease = ifelse((K14048==1 | (K01430==1 & K01429==1)) & K01428==1,1,0)) %>%
  #new variable: Fucose transporter
  mutate(fucose_transporter = ifelse(K02429==1,1,0)) %>%
  #new variable: Glycerol aquaporin transporter
  mutate(glycerol_aquaporin_transporter = ifelse(K02440==1,1,0)) %>%
  #new variable: Glycerol/sorbitol transporter
  mutate(glycerol_sorbitol_transporter = ifelse(K02781==1 &
                                                K02782==1 &
                                                K02783==1,1,0)) %>%
  #new variable: ammonium transporter
  mutate(ammonium_transporter = ifelse(K03320==1,1,0)) %>%
  #new variable: ribose transporter
  mutate(ribose_transporter = ifelse(K10439==1 &
                                     K10440==1 &
                                     K10441==1,1,0)) %>%
  #new variable: xylose transporter
  mutate(xylose_transporter = ifelse(K10543==1 &
                                     K10544==1 &
                                     K10545==1,1,0)) %>%
  #new variable: multiple sugar transporter
  mutate(multiple_sugar_transporter = ifelse(K10546==1 &
                                             K10547==1 &
                                             K10548==1,1,0)) %>%
  #new variable: fructose transporter
  mutate(fructose_transporter = ifelse(K10552==1 &
                                       K10553==1 &
                                       K10554==1,1,0)) %>%
  #new variable: arabinose transporter
  mutate(arabinose_transporter = ifelse(K10537==1 &
                                        K10538==1 &
                                        K10539==1,1,0)) %>%
  #new variable: branched-chain amino acid transporter
  mutate(branched_transporter = ifelse(K01999==1 &
                                       K01997==1 &
                                       K01998==1 &
                                       K01995==1 &
                                       K01996==1,1,0)) %>%
  #new variable: L-amino acid transporter
  mutate(l_amino_transporter = ifelse(K09969==1 &
                                      K09970==1 &
                                      K09971==1 &
                                      K09972==1,1,0)) %>%
  #new variable: glutamate transporter
  mutate(glutamate_transporter = ifelse(K10001==1 &
                                        K10002==1 &
                                        K10003==1 &
                                        K10004==1,1,0)) %>%
  #new variable: capsular transporter
  mutate(capsular_transporter = ifelse(K10107==1 &
                                       K09688==1 &
                                       K09689==1,1,0)) %>%
  #new variable: methylotrophy
  mutate(methanol_dehydrogenase = ifelse(K23995==1,1,0)) %>%
  #remove KO columns
  dplyr::select(-contains("K"))# %>% left_join( annotated_mags_arranged)
  
  
# 4. add antismash results for the presence of carotenoids and ellens' bgc results for exopolysaccharides
carotenoids_df<-read.delim2("analysis/07_annotate_MAGs/summarized_outputs/carotenoids_report.txt",header=F,col.names = c("Genome","BGC_type","carotenoids"))
kegg_df <- kegg_df %>% left_join(carotenoids_df) %>% select(-BGC_type)

bgc_of_interest<-read.delim('analysis/07_annotate_MAGs/bgc_of_interest.txt') %>% filter(function.=="Exopolysaccharide")
emerald_df<- read.delim2("analysis/07_annotate_MAGs/summarized_outputs/bgc_all_good_hits.txt")
emerald_df<- emerald_df %>% filter(nearest_mibig %in% bgc_of_interest$mibig) %>% select(sample, mibig_class) %>% distinct()
kegg_df <- kegg_df %>% mutate(exopolysaccaride = ifelse(Genome %in% emerald_df$sample,1,0 ))

# 5. vitamin modules and calvin cycle
module_kegg<-read.delim("analysis/12_annotate_euks/hdf_prokaryotes.txt")

module_kegg_long<-module_kegg  %>% pivot_longer(-X, names_to = "Genome",values_to = "completeness") %>% 
  mutate(module=gsub("\\_.*","",X))

modules_kegg_sel <- module_kegg_long %>% filter(module %in% c("M00899","M00898","M00897",
                                          "M00123","M00950",
                                          "M00125","M00165","M00122","M00597")) %>%
  group_by(Genome,module) %>% mutate(mean_completeness=mean(completeness)) %>%
  mutate(pathway=case_when(module %in% c("M00899","M00898","M00897") ~"thiamine",
                           module %in% c("M00123","M00950") ~ "biotin",
                           module == "M00125" ~ "riboflavin",
                           module == "M00165" ~ "Calvin_cycle",
                           module == "M00122" ~ "cobalamin",
                           module == "M00597" ~ "photosystem")) %>%
  select(-c(X,completeness)) %>% distinct() %>%
  group_by(Genome,pathway) %>% mutate(presence=max(mean_completeness)) %>%
  #mutate(presence=case_when(completeness==1 ~ "full",
   #                         completeness<1&completeness>0.9 ~ "partial",
    #                        completeness<=0.9 ~ "missing")) %>%
  select(-c(mean_completeness,module)) %>% distinct()

# for nostoc, put calvin cycle as complete, since they lack sedoheptulose 1,7-bisphosphatase, but it's function is performed by fructose-1,6-bisphosphatase II, which is present
modules_kegg_sel$presence[modules_kegg_sel$pathway=="Calvin_cycle" & modules_kegg_sel$Genome %in% (mags_role %>% filter(bac_genus=="Nostoc") %>% pull(Genome))] <- 1


# 6.  viz

df_long<-kegg_df %>% pivot_longer(-Genome, names_to = "pathway",values_to = "presence") %>% 
  rbind(modules_kegg_sel)

df_long<- annotated_mags_arranged %>% 
  inner_join(df_long) %>% mutate(presence_factor = ifelse(
  presence==1,"full",ifelse(presence>0.9,"partial","missing"))) %>%
  mutate(presence_size = ifelse(
    presence>0,1,NA)) %>%
  mutate(bac_family_label = ifelse(bac_family=="Sphingomonadaceae","Sphingo\nmonadaceae",
                                   ifelse(bac_family=="UBA10450","UBA\n10450",
                                          ifelse(bac_family=="Beijerinckiaceae","Beijerin\nckiaceae",bac_family))))
  
#order rows and columns
df_long$Genome<-factor(df_long$Genome,level = annotated_mags_arranged$Genome)

pathway_type<-data.frame("pathway"=c("capsular_transporter",
                                     "branched_transporter" ,         
                                     "l_amino_transporter",           
                                     "glutamate_transporter" ,
                                     "ammonium_transporter",
                                     "urea_transporter",
                                     "ribose_transporter" ,           
                                     "xylose_transporter" ,           
                                     "multiple_sugar_transporter"  ,  
                                     "fructose_transporter" ,         
                                     "arabinose_transporter" ,
                                     "fucose_transporter",
                                     "erythritol_transporter",        
                                     "xylitol_transporter",           
                                     "inositol_transporter",          
                                     "glycerol_transporter",
                                     "glycerol_aquaporin_transporter",
                                     "glycerol_sorbitol_transporter",                      
                                     "sorbitol_mannitol_transporter" ,              
                                     "thiamine",
                                     "riboflavin"  ,   
                                     "cobalamin",
                                     "biotin" ,
                                     "urease",
                                     "nitrogen_fixation",
                                     "methanol_dehydrogenase",
                                     "Calvin_cycle",                  
                                     "carotenoids",
                                     "bacteriochlorophyll",
                                     "photosystem"
),"functions"=c(rep("Other transporters",6),rep("Carbohydrate transporters",13),
                rep("Cofactors",4),rep("C and N metabolism",4), rep("Photo-\nsynthesis",3)
))

df_long<-df_long%>% left_join(pathway_type)
df_long$pathway<-factor(df_long$pathway,level = c("capsular_transporter",
                                                  "branched_transporter" ,         
                                                          "l_amino_transporter",           
                                                          "glutamate_transporter" ,
                                                          "ammonium_transporter",
                                                          "urea_transporter",
                                                          "ribose_transporter" ,           
                                                          "xylose_transporter" ,           
                                                          "multiple_sugar_transporter"  ,  
                                                          "fructose_transporter" ,         
                                                          "arabinose_transporter" ,
                                                          "fucose_transporter",
                                                          "erythritol_transporter",        
                                                          "xylitol_transporter",           
                                                          "inositol_transporter",          
                                                          "glycerol_transporter",
                                                          "glycerol_aquaporin_transporter",
                                                          "glycerol_sorbitol_transporter",                      
                                                          "sorbitol_mannitol_transporter" ,              
                                                         "thiamine",
                                                         "riboflavin"  ,   
                                                         "cobalamin",
                                                         "biotin" ,
                                                         "iron_ion_transport","siderophore_synthesis",
                                                          "urease",
                                                          "nitrogen_fixation",
                                                         "methanol_dehydrogenase",
                                                          "Calvin_cycle",                  
                                                          "carotenoids",
                                                          "bacteriochlorophyll",
                                                          "photosystem",
                                                  "exopolysaccaride"
                                                          ))

df_long$functions<-factor(df_long$functions,level = c("Photo-\nsynthesis","C and N metabolism","Cofactors","Carbohydrate transporters", "Other transporters" ))

ggplot(df_long %>% filter(pathway!="exopolysaccaride"),aes(x=Genome,y=pathway,size=presence_size,shape=presence_factor,color=bac_family))+
  geom_point(size=1.75)+
  scale_colour_manual(values = cols)+
   scale_shape_manual(values=c(16,10),limits = c("full","partial"))+
  guides(size="none",color="none",shape = "none")+theme_minimal()+
  facet_grid(functions~bac_family_label,scales = "free",space="free",labeller = label_wrap_gen(width=5))+
  theme(axis.text.x = element_blank(),
    #axis.text.x = element_text(size =7,angle = 90),
        axis.text.y = element_text(size=7),
        strip.text.x = element_text(size =7),
        strip.text.y = element_text(size =7,angle = 0),
        legend.title = element_text(size=7),
        legend.text = element_text(size=7))+
  xlab("")+ylab("")+
  scale_y_discrete(labels=c("capsular_transporter"="Capsular polysaccharide Transporter kpsMTE",   
                            "branched_transporter" = "Branched-chain amino acid Transporter LivGFHKM" ,         
                            "l_amino_transporter"="L-amino acid Transporter AapJMPQ",           
                            "glutamate_transporter" ="Glutamate/Aspartate Transporter GltIJKL",
                            "ammonium_transporter"="Ammonium Transporter Amt",
                            "urea_transporter"="Urea Transporter urtABCDE",
                            "ribose_transporter" ="Ribose/D-xylose Transporter RbcABC",           
                            "xylose_transporter" ="D-xylose Transporter XylFGH",           
                            "multiple_sugar_transporter" ="Multiple sugar Transporter ChvE-GguAB" ,  
                            "fructose_transporter"="Fructose Transporter FrcABC" ,         
                            "arabinose_transporter"= "Arabinose Transporter AraFGH" ,
                            "fucose_transporter"="Fucose Transporter fucP",
                            "erythritol_transporter"="Erythritol Transporter EryEFG",        
                            "xylitol_transporter"="Xylitol Transporter XltABC",           
                            "inositol_transporter"="Inositol Transporter IatAP-IbpA",          
                            "glycerol_transporter" = "Glycerol Transporter GlpPQSTV",
                            "glycerol_aquaporin_transporter"="Glycerol Transporter GLPF",
                            "glycerol_sorbitol_transporter"="Glucitol/sorbitol Transporter SrlABE",                      
                            "sorbitol_mannitol_transporter"="Sorbitol/mannitol Transporter SmoEFGK" ,              
                            "thiamine"="Thiamine salvage pathway",
                            "riboflavin" ="Riboflavin biosynthesis" ,   
                            "cobalamin"="Cobalamin biosynthesis" ,
                            "biotin"="Biotin biosynthesis" ,
                            "urease"="Urease UreABC",
                            "nitrogen_fixation"="Nitrogenase NifH, Nitrogen fixation",
                            "methanol_dehydrogenase"="Methanol Dehydrogenase, Methylotrophy",
                            "Calvin_cycle"="Calvin cycle",                  
                            "carotenoids"="Carotenoid biosynthesis",
                            "bacteriochlorophyll"="Bacteriochlorophyll biosynthesis",
                            "photosystem"="Anoxygenic Photosystem II"))

ggsave("results/figures/pathway_fig.pdf",width=180,height=100,device="pdf",bg="white",units="mm")


###how many occurrences a given functional group accounts for / how many metagenomes it occures in 
functional_group_summary<-function(group,df_ann,df_occ){
  mag_list<-df_long %>% filter(pathway==group,presence>0.9)
 #number of occurrences of the selected mags
  min_occ_number<-df_occ %>% filter(Genome %in% mag_list$Genome) %>% nrow()
  #number of occurrences of the selected genera
  max_occ_number<-df_occ %>% filter(bac_genus2 %in% mag_list$bac_genus2) %>% nrow()
  #number of metagenomes with the selected mags
  min_mtg_number<-df_occ %>% filter(Genome %in% mag_list$Genome) %>%
    select(metagenome) %>% distinct() %>% nrow()
  #number of metagenomes with the selected genera
  max_mtg_number<-df_occ %>% filter(bac_genus2 %in% mag_list$bac_genus2) %>%
    select(metagenome) %>% distinct() %>% nrow()
  df_out<-data.frame("group"=group,
                   "min_occ_number"=min_occ_number,
                   "max_occ_number"=max_occ_number,
                   "min_mtg_number"=min_mtg_number,
                   "max_mtg_number"=max_mtg_number,
                   "number_mags"=mag_list%>%nrow())
  return(df_out)
}


group_list<-df_long %>% ungroup() %>% select(pathway) %>% distinct()
l<-apply(group_list,1,FUN=functional_group_summary,df_ann=df_long,df_occ=mags_role)
occ_summary<-do.call(rbind,l)

##separately calculate these stats for the three Acetobacteraceae with calvin cycle
mag_list<-df_long %>% filter(pathway=="Calvin_cycle",presence>0.9,bac_family=="Acetobacteraceae")
#number of occurrences of the selected mags
min_occ_number<-mags_role%>% filter(Genome %in% mag_list$Genome) %>% nrow()
#number of occurrences of the selected genera
max_occ_number<-mags_role %>% filter(bac_genus2 %in% mag_list$bac_genus2) %>% nrow()
#number of metagenomes with the selected mags
min_mtg_number<-mags_role %>% filter(Genome %in% mag_list$Genome) %>%
  select(metagenome) %>% distinct() %>% nrow()
#number of metagenomes with the selected genera
max_mtg_number<-mags_role %>% filter(bac_genus2 %in% mag_list$bac_genus2) %>%
  select(metagenome) %>% distinct() %>% nrow()
df_out<-data.frame("group"="Aceto_Calvin_cycle",
                   "min_occ_number"=min_occ_number,
                   "max_occ_number"=max_occ_number,
                   "min_mtg_number"=min_mtg_number,
                   "max_mtg_number"=max_mtg_number,
                   "number_mags"=mag_list%>%nrow())

##how many metagenomes had bacteria with either thiamin, biotin, or cobalamin?
mag_list<-df_long %>% filter(presence>0.9) %>% filter(pathway %in% c("biotin","thiamine","cobalamin"))
#number of occurrences of the selected mags
min_occ_number<-mags_role%>% filter(Genome %in% mag_list$Genome) %>% nrow()
#number of occurrences of the selected genera
max_occ_number<-mags_role %>% filter(bac_genus2 %in% mag_list$bac_genus2) %>% nrow()
#number of metagenomes with the selected mags
min_mtg_number<-mags_role %>% filter(Genome %in% mag_list$Genome) %>%
  select(metagenome) %>% distinct() %>% nrow()
#number of metagenomes with the selected genera
max_mtg_number<-mags_role %>% filter(bac_genus2 %in% mag_list$bac_genus2) %>%
  select(metagenome) %>% distinct() %>% nrow()
df_out2<-data.frame("group"="b vitamins",
                   "min_occ_number"=min_occ_number,
                   "max_occ_number"=max_occ_number,
                   "min_mtg_number"=min_mtg_number,
                   "max_mtg_number"=max_mtg_number,
                   "number_mags"=mag_list%>%nrow())


## barplot to visualize these numbers
df_bar<-occ_summary %>% mutate(mtg_diff=max_mtg_number-min_mtg_number) %>%
  select(group, min_mtg_number, mtg_diff) %>% 
  pivot_longer(-group,names_to = "statistic",values_to = "mtg_num") %>%
  filter(group %in% c("bacteriochlorophyll" ,"cobalamin","biotin", "riboflavin", "thiamine","methanol_dehydrogenase"))
###relevel factors
df_bar$statistic<-as.factor(df_bar$statistic)
levels(df_bar$statistic)[levels(df_bar$statistic)=="mtg_diff"] <- "Number of metagenomes: max estimate"
levels(df_bar$statistic)[levels(df_bar$statistic)=="min_mtg_number"] <- "Number of metagenomes: conservative estimate"
df_bar$statistic <- relevel(df_bar$statistic, "Number of metagenomes: max estimate")

df_bar$group<-as.factor(df_bar$group)
levels(df_bar$group)[levels(df_bar$group)=="bacteriochlorophyll"] <- "Putative AAPs"
levels(df_bar$group)[levels(df_bar$group)=="cobalamin"] <- "Putative Cobalamin producers"
levels(df_bar$group)[levels(df_bar$group)=="biotin"] <- "Putative Biotin producers"
levels(df_bar$group)[levels(df_bar$group)=="riboflavin"] <- "Putative Riboflavin producers"
levels(df_bar$group)[levels(df_bar$group)=="thiamine"] <- "Putative Thiamine producers"
levels(df_bar$group)[levels(df_bar$group)=="methanol_dehydrogenase"] <- "Putative Methylotrophs"
df_bar$group<-factor(df_bar$group,levels = c("Putative Thiamine producers", "Putative Riboflavin producers",
                                             "Putative Biotin producers","Putative Cobalamin producers",
                                             "Putative Methylotrophs","Putative AAPs"))



####plot
ggplot(df_bar,aes(y=group,x=mtg_num,fill=statistic))+
  geom_bar(stat = "identity")+
  xlab("# metagenomes")+ylab("")+theme_bw()+
  scale_fill_manual(values = c("#e4dfec","#12127d"))+
  theme(axis.text.y = element_text(size=10),
        axis.text.x = element_text(size=8),
        axis.title.y = element_text(size=10),
        legend.title = element_blank(),
        legend.text = element_text(size=10),
        legend.position="bottom")

###barplot with depth

####for each metagenome, see if it contains a mag with a given pathway present 
occ_by_mag<- mags_role %>% left_join(df_long,relationship = "many-to-many")  %>%
  group_by(metagenome,pathway) %>% summarize(presence_mag=sum(presence,na.rm=T)) %>%
  pivot_wider(names_from = pathway,values_from = presence_mag, values_fill = 0) %>%
  pivot_longer(-metagenome,names_to="pathway",values_to = "presence_mag") %>% 
  filter(pathway!="NA")

####for each metagenome, see if it contains a genus whose representatives have a given pathway present 
pathway_presence_by_genus<-function(group,df_ann,df_occ){
  mag_list<-df_long %>% filter(pathway==group,presence>0)
  genus_list<-mag_list$bac_genus2 %>% unique()
  genus_df<-df_occ %>% filter(bac_genus2 %in% genus_list) %>% group_by(metagenome) %>% summarize(presence_genus=n()) %>% mutate(pathway=group)
  return(genus_df)
}
l2<-apply(group_list,1,FUN=pathway_presence_by_genus,df_ann=df_long,df_occ=mags_role)
occ_by_genus<-do.call(rbind,l2) %>%
  pivot_wider(names_from = pathway,values_from = presence_genus, values_fill = 0) %>%
  pivot_longer(-metagenome,names_to="pathway",values_to = "presence_genus")

####combine all data and add depth
df_all<-occ_by_mag %>% left_join(occ_by_genus)
df_all$presence_genus[is.na(df_all$presence_genus)]<-0

depth<-read.delim("analysis/03_metagenome_reanalysis/bp_report.txt",header = F)
colnames(depth)<-c("metagenome","depth")
df_all <- df_all %>% left_join(depth)

####create a group variable
df_all <- df_all %>% mutate(presence=ifelse(presence_mag>0,"conservative estimate",
                                  ifelse(presence_genus>0,"max estimate","absent")),
                            presence_num=ifelse(presence_mag>0,1,
                                                 ifelse(presence_genus>0,2,3)))

####plot
df_all<-df_all  %>%  
  arrange(across(.cols=c("presence_num","depth"))) %>% 
  rowid_to_column()
df_all$presence<-factor(df_all$presence,levels = c("conservative estimate","max estimate","absent"))

df_bar2<-df_all %>%
  filter(pathway %in% c("bacteriochlorophyll" ,"cobalamin","biotin", "riboflavin", "thiamine","methanol_dehydrogenase","exopolysaccaride"))
df_bar2$pathway<-as.factor(df_bar2$pathway)
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="bacteriochlorophyll"] <- "Putative AAPs"
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="cobalamin"] <- "Putative Cobalamin producers"
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="biotin"] <- "Putative Biotin producers"
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="riboflavin"] <- "Putative Riboflavin producers"
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="thiamine"] <- "Putative Thiamine producers"
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="methanol_dehydrogenase"] <- "Putative Methylotrophs"
levels(df_bar2$pathway)[levels(df_bar2$pathway)=="exopolysaccaride"] <- "Putative Exopolysaccharide producers"

plot_by_pathway<-function(df,selected_pathway){
  plot<-ggplot(df %>% filter(pathway==selected_pathway))  +
  geom_bar(aes(x =  reorder(metagenome, rowid),  y = depth, fill = presence), stat = "identity",  width = 0.8)+
  ylab("sequencing depth, bp")+ guides(fill="none")+
  scale_fill_manual(values = c("#030357","#5e5ec5","#e4dfec"))+
  theme(axis.text.x = element_blank(),axis.title.x = element_blank(),axis.ticks.x = element_blank())
  return(plot)
}
plot1<-plot_by_pathway(df_bar2,"Putative AAPs")
plot2<-plot_by_pathway(df_bar2,"Putative Methylotrophs")
plot3<-plot_by_pathway(df_bar2,"Putative Cobalamin producers")
plot4<-plot_by_pathway(df_bar2,"Putative Biotin producers")
plot5<-plot_by_pathway(df_bar2,"Putative Riboflavin producers")
plot6<-plot_by_pathway(df_bar2,"Putative Thiamine producers")
plot7<-plot_by_pathway(df_bar2,"Putative Exopolysaccharide producers")

df_bar2 %>% filter(presence=="absent") %>% group_by(pathway) %>% summarize(n=n()) %>% arrange(n)

library(patchwork)
plot5 / plot3 / plot7 / plot1 / plot2 / plot4 / plot6

ggsave("results/pathway_presence_cov.svg",width=120,height=120,device="svg",bg="white",units="mm")


###which samples have no AAPs but high depth?
mtg_info<-read.delim("analysis/03_metagenome_reanalysis/all_metagenome_reanalysis.txt")
no_aap_deep<-df_all %>% filter(pathway=="photosystem",presence_genus==0,depth>5000000000) %>%
  left_join(mtg_info,by=c("metagenome"="Run"))
write.table(no_aap_deep,"analysis/05_MAGs/tables/deep_metagenomes_no_aap.txt",sep="\t",quote = F, row.names = F)


###which have no cobalamin synthesizers but high depth?
no_com_deep<-df_all %>% filter(pathway=="cobalamin",presence_genus==0,depth>5000000000) %>%
  left_join(mtg_info,by=c("metagenome"="Run"))


###how many aceto and bejerinckos were among 63?
df_long %>% filter(bac_family %in% c("Acetobacteraceae","Beijerinckiaceae")) %>%
  select(Genome) %>% distinct()




ggplot(df_long,aes(x=Genome,y=pathway,size=presence_size,shape=presence_factor,color=bac_genus2))+
  geom_point(size=1.75)+
  #scale_colour_manual(values = cols)+
  scale_shape_manual(values=c(16,10),limits = c("full","partial"))+
  theme_minimal()+
  facet_grid(functions~bac_family_label,scales = "free",space="free",labeller = label_wrap_gen(width=5))+
  theme(axis.text.x = element_blank(),
        axis.text.y = element_text(size=7),
        strip.text.x = element_text(size =7),
        strip.text.y = element_text(size =7,angle = 0),
        legend.title = element_text(size=7),
        legend.text = element_text(size=7))+
  xlab("")+ylab("")+
  scale_y_discrete(labels=c("capsular_transporter"="Capsular polysaccharide Transporter kpsMTE",   
                            "branched_transporter" = "Branched-chain amino acid Transporter LivGFHKM" ,         
                            "l_amino_transporter"="L-amino acid Transporter AapJMPQ",           
                            "glutamate_transporter" ="Glutamate/Aspartate Transporter GltIJKL",
                            "ammonium_transporter"="Ammonium Transporter Amt",
                            "urea_transporter"="Urea Transporter urtABCDE",
                            "ribose_transporter" ="Ribose/D-xylose Transporter RbcABC",           
                            "xylose_transporter" ="D-xylose Transporter XylFGH",           
                            "multiple_sugar_transporter" ="Multiple sugar Transporter ChvE-GguAB" ,  
                            "fructose_transporter"="Fructose Transporter FrcABC" ,         
                            "arabinose_transporter"= "Arabinose Transporter AraFGH" ,
                            "fucose_transporter"="Fucose Transporter fucP",
                            "erythritol_transporter"="Erythritol Transporter EryEFG",        
                            "xylitol_transporter"="Xylitol Transporter XltABC",           
                            "inositol_transporter"="Inositol Transporter IatAP-IbpA",          
                            "glycerol_transporter" = "Glycerol Transporter GlpPQSTV",
                            "glycerol_aquaporin_transporter"="Glycerol Transporter GLPF",
                            "glycerol_sorbitol_transporter"="Glucitol/sorbitol Transporter SrlABE",                      
                            "sorbitol_mannitol_transporter"="Sorbitol/mannitol Transporter SmoEFGK" ,              
                            "thiamine"="Thiamine salvage pathway",
                            "riboflavin" ="Riboflavin biosynthesis" ,   
                            "cobalamin"="Cobalamin biosynthesis" ,
                            "biotin"="Biotin biosynthesis" ,
                            "urease"="Urease UreABC",
                            "nitrogen_fixation"="Nitrogenase NifH, Nitrogen fixation",
                            "methanol_dehydrogenase"="Methanol Dehydrogenase, Methylotrophy",
                            "Calvin_cycle"="Calvin cycle",                  
                            "carotenoids"="Carotenoid biosynthesis",
                            "bacteriochlorophyll"="Bacteriochlorophyll biosynthesis",
                            "photosystem"="Anoxygenic Photosystem II"))






