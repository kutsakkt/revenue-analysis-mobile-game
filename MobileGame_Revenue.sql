--- ВЫРУЧКА по странам
select ui.country, sum(t.revenue) as revenue
from mobile_game.transactions t
left join mobile_game.user_info ui 
	on t.user_id = ui.user_id
group by 1
--- наибольшая выручка наблюдается у США, что может быть связано с высоким числом пользователей в стране

--- ВЫРУЧКА НА ПОЛЬЗОВАТЕЛЯ по странам
select ui.country, sum(t.revenue)/count(t.user_id) as revenue
from mobile_game.transactions t
left join mobile_game.user_info ui 
	on t.user_id = ui.user_id
group by 1
--- для каждой страны показатель выручки с одного пользователя примерно равны

--- ВЫРУЧКА по каналам
select ut.channel, sum(t.revenue) as revenue
from mobile_game.users_touches ut
left join mobile_game.transactions t 
	on ut.user_id = t.transaction_id
group by 1
order by 2 desc
--- наибольшая выручка наблюдается у канала applovin

--- DAILY REVENUE для каждой страны по каналам
select ut.touch_date, ui.country, sum(t.revenue) as revenue
from mobile_game.users_touches ut
left join mobile_game.transactions t 
	on ut.user_id = t.transaction_id
left join mobile_game.user_info ui 
	on ut.user_id = ui.user_id
where ut.channel = 'applovin'
group by 1,2
--- Наблюдается падение выручки для канала 'organic'с 8 марта 2023 года во всех странах. Графики приведены в .doc файле

--- DAU в разрезе по платформам
select 
	session_start_time::date as event_date,
	ui.platform,
	count(distinct user_id) as dau
from mobile_game.sessions s 
join mobile_game.user_info ui using(user_id)
where ui.platform = 'iOS'
group by 1,2
--- В данных ошибка: канал ios записан как iOS для четырех дат

--- DAU в размере по каналам
select 
	session_start_time::date as event_date,
	ut.channel as channel,
	count(distinct user_id) as dau
from mobile_game.sessions s 
join mobile_game.users_touches ut using(user_id)
group by 1,2
--- наблюдается падение DAU, начиная с 14 декабря 2023 для всех каналов, платформ и стран

--- NEW INSTALLS по каналам
select ui.user_start_date, ut.channel, count(*) as new_users
from mobile_game.user_info ui 
left join mobile_game.users_touches ut 
	on ui.user_id = ut.user_id
group by 1,2
--- в октябре 2023 показатель падает для канала applovin
--- имеются данные от 01 января 2025 гогда по user_start_date, в то время как по другим переменным отсутствуют за эту дату
--- нет данных между декабрем 2023 года и январем 2025 

--- NEW INSTALLS по каналу applovin по странам
select ui.user_start_date, ut.channel, ui.country, count(*) as new_users
from mobile_game.user_info ui 
left join mobile_game.users_touches ut 
	on ui.user_id = ut.user_id
where ut.channel = 'applovin'
group by 1,2,3
--- падение в октябре 2023 происходит по всем странам

--- RETENTION первого дня по странам
select 
	ui.user_start_date, ui.country,	count(s.user_id)::float/count(*) as retention_first_day
from mobile_game.user_info ui 
left join mobile_game.sessions s 
	on ui.user_id = s.user_id
	and ui.user_start_date + 1 = s.session_start_time::date
group by 1,2
--- наблюдается ошибка в датах: по США есть данные за январь 2023 и январь 2025
--- в то время как по остальным странам данные есть с марта по декабрь 2023

--- RETENTION первого дня по каналам
select 
	ui.user_start_date, ut.channel,	count(s.user_id)::float/count(*) as retention_first_day
from mobile_game.user_info ui 
left join mobile_game.sessions s 
	on ui.user_id = s.user_id
	and ui.user_start_date + 1 = s.session_start_time::date
left join mobile_game.users_touches ut 
	on ui.user_id = ut.user_id
group by 1,2
--- у канала applovin минимальные retention приходится на 3 октября, что может быть связано с последующим падением dau

--- чтобы детальнее изучить returning users, посмотрим на количество дней пользования
select 
	ut.channel, (s.session_start_time::date - ui.user_start_date) as active_days, count(*)
from mobile_game.user_info ui 
left join mobile_game.sessions s 
	on ui.user_id = s.user_id
left join mobile_game.users_touches ut 
	on ui.user_id =ut.user_id
where s.session_start_time::date >= ui.user_start_date
group by 1,2
--- более 50% пользователей заходят в игру от 1 до 4 дней

--- количество активных дней по странам
select 
	(s.session_start_time::date  - ui.user_start_date) as active_day,
	ui.country as country,
	count(*) as qty
from mobile_game.user_info ui 
join mobile_game.sessions s on ui.user_id = s.user_id
where 
	1=1
	and s.session_start_time::date >= ui.user_start_date
group by 1,2
--- по странам всё равномерно, нет падений


--- ARPDAU по странам
with daily_metrics_geo as
	(select 
    s.session_start_time::date as event_date,
	ui.country as country,
	count(distinct user_id) as dau,
	sum(t.revenue)/count(distinct(t.event_date)) as daily_revenue,
	(sum(t.revenue)/count(distinct(t.event_date)))/(count(distinct user_id)) as arpdau
from mobile_game.sessions s 
join mobile_game.user_info ui using(user_id)
join mobile_game.transactions t using(user_id)
group by s.session_start_time::date, ui.country)

select event_date, country, arpdau
from daily_metrics_geo
--- динамика по дням равномерная, без резких изменений
--- наибольший arpdau у Италии, наименьший - у США

--- ARPDAU по каналам
with daily_metrics_geo as
	(select 
    s.session_start_time::date as event_date,
	ut.channel as channel,
	count(distinct user_id) as dau,
	sum(t.revenue)/count(distinct(t.event_date)) as daily_revenue,
	(sum(t.revenue)/count(distinct(t.event_date)))/(count(distinct user_id)) as arpdau
from mobile_game.sessions s 
join mobile_game.users_touches ut using(user_id)
join mobile_game.transactions t using(user_id)
group by s.session_start_time::date, ut.channel)

select event_date, channel, arpdau
from daily_metrics_geo
--- по всем каналам наблюдается плавное снижение показателей от марта к декабрю


--- DAILY CONVERSION
with tmp as (
	select s.session_start_time::date as date, ui.country as country, s.user_id as user_id, case when count(t.transaction_id) > 0 then 1 else 0 end as has_transactions
	from mobile_game.sessions s
	left join mobile_game.transactions t
		on s.session_start_time::date = t.event_date::date
			and s.user_id = t.user_id
	left join mobile_game.user_info ui
		on s.user_id = ui.user_id	
	group by s.session_start_time::date, ui.country, s.user_id
)
select t.date as date, t.country as country, count(t.user_id) as dau, sum(t.has_transactions) as daily_customers, (sum(t.has_transactions)::float / count(t.user_id)) as daily_conversion
from tmp t
where t.country = 'India'
group by t.date, t.country
--- в Индии наблюдается плавный рост и потом падение конверсии от 24 ноября 2023
--- это может быть связано с падение daily_revenue в Индии от 1 декабря 2023

--- DAILY REVENUE в Индии
with daily_metrics_geo as
	(select 
    s.session_start_time::date as event_date,
	ui.country as country,
	count(distinct user_id) as dau,
	sum(t.revenue)/count(distinct(t.event_date)) as daily_revenue,
	(sum(t.revenue)/count(distinct(t.event_date)))/(count(distinct user_id)) as arpdau
from mobile_game.sessions s 
join mobile_game.user_info ui using(user_id)
join mobile_game.transactions t using(user_id)
group by s.session_start_time::date, ui.country)

select event_date, country, daily_revenue
from daily_metrics_geo
where country='India'
--- падение daily_revenue в Индии от 1 декабря 2023

--- ARPPU по странам
with tmp as (
	select s.session_start_time::date as date, ui.country as country, s.user_id as user_id, case when count(t.transaction_id) > 0 then 1 else 0 end as has_transactions,
	sum(t.revenue)/count(distinct(t.event_date)) as daily_revenue
	from mobile_game.sessions s
	left join mobile_game.transactions t
		on s.session_start_time::date = t.event_date::date
			and s.user_id = t.user_id
	left join mobile_game.user_info ui
		on s.user_id = ui.user_id	
	group by s.session_start_time::date, ui.country, s.user_id
)
select t.date, t.country, count(t.user_id) as dau, (t.daily_revenue/sum(t.has_transactions)) as arppu
from tmp t
group by t.date, t.country, t.country, t.daily_revenue
--- пики ARPPU приходятся на Японию 13 марта и Индию 6 октября