Select o.eisuot_id,
       substring(gg.name, 8, 3)                        as 'Филиал',
       substring(ggg.name, 14, 2)                      as 'Предприятие',
       --   o.pasp_address,
       o.tech_place_encoding                           as 'Кодировка технического места',
       o.network_number,
       o.network_length                                as 'Длина участка',
       round((o.network_length * o.pipeline_count), 4) as 'длина в однотрубке',
       o.is_ownerless                                  as 'Бесхоз?',
       o.pipeline_count                                as 'Количество труб',
       u.name                                          as 'балансовая принадлежность по недвижимости',
       k.name                                          as 'балансовая принадлежность по эксплуатации',
       l.name                                          as 'Тип участка тепловой сети',
       o.composite_address                             as 'Тех устройство из АСОТ',
       o.composite_heat_network_index                  as 'Номер в Тех устройстве',
       e.address                                       as 'Адрес составного участка',
       b.name                                          as 'Источник собственный',
       o.pasp_pipe_count                               as 'количество трубопроводов',
       date(o.startup_date)                            as 'дата ввода в эксплуатацию',
       date(o.last_relaying_date)                      as 'дата последней перекладки',
       y.name                                          as 'Тип канала',
       y1.name                                         as 'Вид прокладки',
       y2.name                                         as 'Тип теплоносителя',
       o.decommissioned_date                           as 'Дата выведения из эксплуатации',
       o.previous_heat_network_muid                    as 'Предыдущий участок тепловой сети',
       o.network_start_address                         as 'адрес начала участка',
       o.network_end_address                           as 'адрес конца участка',
       pp.ttt                                          as 'Условный диаметр',
       pp.Isol                                         as 'Изоляция',

       (CASE
            WHEN o.last_relaying_date IS NOT NULL THEN (
                    (YEAR(CURRENT_DATE) - YEAR(o.last_relaying_date)) - /* step 1 */
                    (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(o.last_relaying_date, '%m%d')) /* step 2 */
                )
            else
                (
                        (YEAR(CURRENT_DATE) - YEAR(o.startup_date)) - /* step 1 */
                        (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(o.startup_date, '%m%d')) /* step 2 */
                    ) end
           )                                           as age

# o.pasp_address as 'адрес УТС из АС "Паспортизация"',
# o.network_start_address_arch as 'Адрес начала сети (архивный)',
# o.network_end_address_arch as 'Адрес конца сети (архивный)'


from ots_heat_networks o
         left join vts_balance_types_est u on o.balance_type_est_muid = u.muid
         left join vts_balance_types_exp k on o.balance_type_exp_muid = k.muid
         left join vts_heat_network_types l on o.heat_network_type_muid = l.muid
         left join ots_complex_heat_networks e on o.complex_network_muid = e.muid
         left join ots_heat_sources b on o.heat_source_muid = b.muid
         left join vts_channel_types y on o.channel_type_muid = y.muid
         left join vts_laying_types y1 on o.laying_muid = y1.muid
         left join vts_heat_transfer_agent_types y2 on o.heat_transfer_agent_type_muid = y2.muid
         left join vts_branches gg on o.branch_muid = gg.muid
         left join vts_departments ggg on o.department_muid = ggg.muid
         left join vts_ppl_insulation_type zz on o.pasp_isolation_type_code = zz.muid
    #          left join ots_pipelines r on u.muid = r.muid
#          left join vts_ppl_orifice q on r.orifice_muid=q.muid
         left join (select p.heat_network_muid,
                           max(b.orifice) as ttt,
                           (CASE
                                WHEN cc.shortname IS NOT NULL THEN (
                                    cc.shortname
                                    )
                                else
                                    (c.shortname) end
                               )          as Isol
                           --        c.name, c.shortname,cc.name
                    from ots_pipelines p
                             left join vts_ppl_orifice b on p.orifice_muid = b.muid
                             left join vts_ppl_insulation_type c on p.insulation_type_short_muid = c.muid
                             left join vts_ppl_insulation_type cc on p.insulation_type_muid = cc.muid
                    group by p.muid, p.insulation_type_muid) pp on o.muid = pp.heat_network_muid

where o.sign_deleted = '0'
  and o.unused = '0'
  and o.eisuot_id is not null
group by o.eisuot_id

-- left join oas_districts t on o.region_muid=t.muid

-- where eisuot_id is not null