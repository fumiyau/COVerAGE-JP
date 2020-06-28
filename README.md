# COVerAGE-JP
# Database for COVID-19 deaths in Japan by age, sex, date, and region

This database collects COVID-19 deaths by age, sex, date, and region in Japan. As with other causes of deaths, deaths related to COVID-19 are reported by local public health center (Hokenjo), which is located in every prefecture and major metropolitan/large cities. 47 prefectures and some metropolitan cities then collect the information about COVID-19 cases and deaths to report the Ministry of Health, Labour, and Welfare (MHLW). Although MHLW provides a summary statistics about the COVID-19 cases and deaths on their webpage, the distribution broken down by age and sex is not available, that leads many volunteering organizations to collect COVID-19 information based on prefectural/municipality reports.

However, even these databases do not provide COVID-19 deaths by age and sex. This database thus aims to fill in the gap by collecting COVID-19 related deaths reported by various sources as I discuss below, including prefectures’ press releases or media sources.

# Collection of data sources
Information about COVID-19 deaths is based on periodic reports by prefectures, major metropolitan cities, and news sources. The priority was given to the local government’s website to see if there are any COVID-19 deaths reported. Some prefectures with larger COVID-19 cases, like Tokyo, Osaka or Hokkaido, release daily reports on cases and deaths with information about the date of death, age, sex. Other prefectures, where the number of  COVID-19 deaths tends to be small, deliver a daily briefing but do not necessarily upload their press release online. This leads to the value to look at media sources based on the prefectural or municipality briefings. For these prefectures, I collected death information about COVID-19 cases from news sources. Priorities are local newspapers, followed by NHK and other major newspapers like Asahi Shimbun. In collecting information, I tried to omit news sources published in news aggregators (like Yahoo Japan which often makes older articles not available after a short period of time). 

# Variables
- Date: date of occurence
- Reporting: date of reporting
- RegionNo: number assigned to each prefecture
- RegionJp: name of prefecture in Japanese
- Region: name of prefecture in English
- Age and Sex: case's age and sex
- URL: url to sources
