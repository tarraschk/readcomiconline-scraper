require 'selenium-webdriver'
require 'open-uri'
require 'fileutils'

$COMICS_URL = [
    "http://readcomiconline.to/Comic/Deadpool-2016"
]

begin
   driver = Selenium::WebDriver.for :chrome
   wait = Selenium::WebDriver::Wait.new(timeout: 60)
   driver.manage.timeouts.implicit_wait = 600 # Durée des timeout
   
   # Parcours des comics
   $COMICS_URL.each do |url|
       puts "* Connexion à #{url.to_s}..."
       driver.navigate.to url
       wait.until { driver.title != 'Please wait 5 seconds...' }
       
       # Recherche des issues du comics
       $ISSUES_URL = driver.find_elements(css: "div.barContent.episodeList > div > table > tbody > tr > td:nth-child(1) > a").reverse.map{ |x| x.attribute("href") }
       puts "* Issues détectées :"
       puts $ISSUES_URL
       
       # Parcours des issues du comics
       $ISSUES_URL.each do |issue|
           puts "* Ouverture de l'issue #{issue.to_s}"
           issue_url = issue + "&readType=0&quality=hq" # On demande l'affichage des images 1 par 1
           driver.navigate.to issue_url
           
           # Recherche des images de l'issue, qui sont stockées dans le tableau JS "lstImages"
           #$IMG_URL = driver.find_elements(css: "#divImage > p > img").map { |x| x.attribute("src") }
           $IMG_URL = driver.execute_script("return lstImages")
           
           # Création du répertoire pour stocker les images
           dir = ['.', url.split('/').last.strip, issue.split('/').last.split('?').first.strip].join('/')
           unless File.directory?(dir)
             FileUtils.mkdir_p(dir)
           end
           
           # Téléchargement des images
           puts "Téléchargement de l'issue..."
           i = 0
           $IMG_URL.each do |img|
               i_str = "%08d" % i
               i = i + 1
               File.open(dir+'/'+ i_str+'.jpg', "wb") do |file_write|
                 open(img, 'rb') do |file_read|
                   file_write.write(file_read.read)
                 end
               end
           end
           puts "Terminé !"
       end
   end
ensure
   driver.close 
end