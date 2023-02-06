select typ,
       sum(iznos * yyy.network_length * yyy.pipeline_count) / sum(
               yyy.network_length * yyy.pipeline_count) as sr_vz_iznos
from (select yy.network_length,
             yy.pipeline_count,
             yy.eisuot_id,
             yy.unused,
             yy.sign_deleted,
             yy.balance_type_exp_muid,
             (case
                  WHEN t.name = 'разводящий' then 'РС'
                  WHEN t.name = 'магистральный' then 'МС'
                  WHEN t.name = 'тепловой ввод' then 'ТВ'
                 end) as typ,


             (CASE
                  WHEN Isol = 'ППУ' and age >= 30 THEN 100
                  WHEN Isol = 'ППУ' and age < 30 THEN age / 30 * 100
                  WHEN Isol = 0 and t.name = 'Разводящая' and age >= 15 THEN 100
                  WHEN Isol = 0 and t.name = 'Разводящая' and age < 15 THEN age / 15 * 100
                  WHEN Isol = 0 and t.name <> 'Разводящая' and age >= 25 THEN 100
                  WHEN Isol = 0 and t.name <> 'Разводящая' and age < 25 THEN age / 25 * 100
                 end) as iznos
      from (select *,
                   (CASE
                        WHEN pp.last_relaying_date IS NOT NULL THEN (
                                (YEAR(CURRENT_DATE) - YEAR(pp.last_relaying_date)) - /* step 1 */
                                (DATE_FORMAT(CURRENT_DATE, '%m%d') <
                                 DATE_FORMAT(pp.last_relaying_date, '%m%d')) /* step 2 */
                            )
                        else
                            (
                                    (YEAR(CURRENT_DATE) - YEAR(pp.startup_date)) - /* step 1 */
                                    (DATE_FORMAT(CURRENT_DATE, '%m%d') <
                                     DATE_FORMAT(pp.startup_date, '%m%d')) /* step 2 */
                                ) end
                       ) as age
            from ots_heat_networks pp) yy
               left join vts_heat_network_types t on yy.heat_network_type_muid = t.muid
               left join (select p.heat_network_muid,
                                 (CASE
                                      WHEN cc.shortname IS NOT NULL THEN (
                                          cc.shortname
                                          )
                                      else
                                          (c.shortname) end
                                     ) as Isol
                          from ots_pipelines p

                                   left join vts_ppl_insulation_type c on p.insulation_type_short_muid = c.muid
                                   left join vts_ppl_insulation_type cc on p.insulation_type_muid = cc.muid) kk
                         on yy.muid = kk.heat_network_muid) yyy

where yyy.sign_deleted = '0'
  and yyy.unused = '0'
  and yyy.eisuot_id is not null
  and yyy.balance_type_exp_muid = 3
  and yyy.typ is not null
group by yyy.typ



