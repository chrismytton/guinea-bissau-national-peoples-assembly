#!/usr/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

require 'pry'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def extract_regiao(regiao)
  return regiao unless regiao.start_with?('Região de')
  regiao.gsub('Região de ', '')
end

def scrape_list(url)
  original_url = 'http://www.gbissau.com/?page_id=11253'
  noko = noko_for(url)
  parties = noko.css('div.entry p span')
  parties.each do |party|
    party_matches = party.text.match(/^(?<party>.*?) \((?<party_id>.*?)\)$/)
    people = party.xpath('following::ol[1]/li')
    people.each do |person|
      person_matches = person.text.match(/^(?<name>.*?) ?\(círculo (?<circulo>\d+?), (?<area>.*?), (?<regiao>.*?)\)$/)
      next if person_matches.nil?
      area_id = "ocd-division/country:gw/" \
        "região:#{extract_regiao(person_matches[:regiao])}/" \
        "círculo:#{person_matches[:circulo]}"
      data = {
        name: person_matches[:name],
        party_id: party_matches[:party_id],
        party: party_matches[:party],
        area_id: area_id.downcase,
        area: person_matches[:area],
        source: original_url
      }
      ScraperWiki.save_sqlite([:name, :party_id, :area_id], data)
    end
  end
end

# Website doesn't work directly due to Incapsula bot blocking
# scrape_list('http://www.gbissau.com/?page_id=11253')

scrape_list('gbissau-members.html')
