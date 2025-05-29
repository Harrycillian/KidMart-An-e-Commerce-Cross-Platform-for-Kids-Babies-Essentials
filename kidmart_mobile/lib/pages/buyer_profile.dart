import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'buyer_toapprove.dart';
import 'buyer_toship.dart';
import 'buyer_toreceive.dart';
import 'buyer_home.dart';
import 'buyer_notif.dart';
import 'buyer_cart.dart';
import 'login.dart';
import '../config/constants.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;
  String error = '';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController brgyController = TextEditingController();

  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;

  List<String> regions = [];
  List<String> provinces = [];
  List<String> cities = [];

  final Map<String, Map<String, List<String>>> addressData = {
  "Region I - Ilocos Region": {
    "Ilocos Norte": ["Adams", "Bacarra", "Badoc", "Bangui", "Banna", "Batac", "Burgos", "Carasi", "Currimao", "Dingras", "Dumalneg", "Laoag", "Marcos", "Nueva Era", "Pagudpud", "Paoay", "Pasuquin", "Piddig", "Pinili", "San Nicolas", "Sarrat", "Solsona", "Vintar"],
    "Ilocos Sur": ["Alilem", "Banayoyo", "Bantay", "Burgos", "Cabugao", "Candon", "Caoayan", "Cervantes", "Galimuyod", "Gregorio Del Pilar", "Lidlidda", "Magsingal", "Nagbukel", "Narvacan", "Quirino", "Salcedo", "San Emilio", "San Esteban", "San Ildefonso", "San Juan", "San Vicente", "Santa", "Santa Catalina", "Santa Cruz", "Santa Lucia", "Santa Maria", "Santiago", "Santo Domingo", "Sigay", "Sinait", "Sugpon", "Suyo", "Tagudin", "Vigan"],
    "La Union": ["Agoo", "Aringay", "Bacnotan", "Bagulin", "Balaoan", "Bangar", "Bauang", "Burgos", "Caba", "Luna", "Naguilian", "Pugo", "Rosario", "San Fernando", "San Gabriel", "San Juan", "Santo Tomas", "Santol", "Sudipen", "Tubao"],
    "Pangasinan": ["Agno", "Aguilar", "Alaminos", "Alcala", "Anda", "Asingan", "Balungao", "Bani", "Basista", "Bautista", "Bayambang", "Binalonan", "Binmaley", "Bolinao", "Bugallon", "Burgos", "Calasiao", "Dagupan", "Dasol", "Infanta", "Labrador", "Laoac", "Lingayen", "Mabini", "Malasiqui", "Manaoag", "Mangaldan", "Mangatarem", "Mapandan", "Natividad", "Pozorrubio", "Rosales", "San Carlos", "San Fabian", "San Jacinto", "San Manuel", "San Nicolas", "San Quintin", "Santa Barbara", "Santa Maria", "Santo Tomas", "Sison", "Sual", "Tayug", "Umingan", "Urbiztondo", "Urdaneta", "Villasis"]
    },
    "Region II - Cagayan Valley": {
      "Batanes": ["Basco", "Itbayat", "Ivana", "Mahatao", "Sabtang", "Uyugan"],
      "Cagayan": ["Abulug", "Alcala", "Allacapan", "Amulung", "Aparri", "Baggao", "Ballesteros", "Buguey", "Calayan", "Camalaniugan", "Claveria", "Enrile", "Gattaran", "Gonzaga", "Iguig", "Lal-lo", "Lasam", "Pamplona", "Peñablanca", "Piat", "Rizal", "Sanchez-Mira", "Santa Ana", "Santa Praxedes", "Santa Teresita", "Santo Niño", "Solana", "Tuao", "Tuguegarao"],
      "Isabela": ["Alicia", "Angadanan", "Aurora", "Benito Soliven", "Burgos", "Cabagan", "Cabatuan", "Cauayan", "Cordon", "Delfin Albano", "Dinapigue", "Divilacan", "Echague", "Gamu", "Ilagan", "Jones", "Luna", "Maconacon", "Mallig", "Naguilian", "Palanan", "Quezon", "Quirino", "Ramon", "Reina Mercedes", "Roxas", "San Agustin", "San Guillermo", "San Isidro", "San Manuel", "San Mariano", "San Mateo", "San Pablo", "Santa Maria", "Santiago", "Santo Tomas", "Tumauini"],
      "Nueva Vizcaya": ["Alfonso Castañeda", "Ambaguio", "Aritao", "Bagabag", "Bambang", "Bayombong", "Diadi", "Dupax Del Norte", "Dupax Del Sur", "Kasibu", "Kayapa", "Quezon", "Santa Fe", "Solano", "Villaverde"],
      "Quirino": ["Aglipay", "Cabarroguis", "Diffun", "Maddela", "Nagtipunan", "Saguday"]
    },
    "Region III - Central Luzon": {
      "Aurora": ["Baler", "Casiguran", "Dilasag", "Dinalungan", "Dingalan", "Dipaculao", "Maria Aurora", "San Luis"],
      "Bataan": ["Abucay", "Bagac", "Balanga", "Dinalupihan", "Hermosa", "Limay", "Mariveles", "Morong", "Orani", "Orion", "Pilar", "Samal"],
      "Bulacan": ["Angat", "Balagtas", "Baliuag", "Bocaue", "Bulakan", "Bustos", "Calumpit", "Doña Remedios Trinidad", "Guiguinto", "Hagonoy", "Malolos", "Marilao", "Meycauayan", "Norzagaray", "Obando", "Pandi", "Paombong", "Plaridel", "Pulilan", "San Ildefonso", "San Jose del Monte", "San Miguel", "San Rafael", "Santa Maria"],
      "Nueva Ecija": ["Aliaga", "Bongabon", "Cabanatuan", "Cabiao", "Carranglan", "Cuyapo", "Gabaldon", "Gapan", "General Mamerto Natividad", "General Tinio", "Guimba", "Jaen", "Laur", "Licab", "Llanera", "Lupao", "Muñoz", "Nampicuan", "Palayan", "Pantabangan", "Peñaranda", "Quezon", "Rizal", "San Antonio", "San Isidro", "San Jose", "San Leonardo", "Santa Rosa", "Santo Domingo", "Talavera", "Talugtug", "Zaragoza"],
      "Pampanga": ["Angeles", "Apalit", "Arayat", "Bacolor", "Candaba", "Floridablanca", "Guagua", "Lubao", "Mabalacat", "Macabebe", "Magalang", "Masantol", "Mexico", "Minalin", "Porac", "San Fernando", "San Luis", "San Simon", "Santa Ana", "Santa Rita", "Santo Tomas", "Sasmuan"],
      "Tarlac": ["Anao", "Bamban", "Camiling", "Capas", "Concepcion", "Gerona", "La Paz", "Mayantoc", "Moncada", "Paniqui", "Pura", "Ramos", "San Clemente", "San Jose", "San Manuel", "Santa Ignacia", "Tarlac City", "Victoria"],
      "Zambales": ["Botolan", "Cabangan", "Candelaria", "Castillejos", "Iba", "Masinloc", "Olongapo", "Palauig", "San Antonio", "San Felipe", "San Marcelino", "San Narciso", "Santa Cruz", "Subic"]
    },       
    "Region IV-A - CALABARZON": {
      "Batangas": ["Agoncillo", "Alitagtag", "Balayan", "Balete", "Batangas City", "Bauan", "Calaca", "Calatagan", "Cuenca", "Ibaan", "Laurel", "Lemery", "Lian", "Lipa", "Lobo", "Mabini", "Malvar", "Mataasnakahoy", "Nasugbu", "Padre Garcia", "Rosario", "San Jose", "San Juan", "San Luis", "San Nicolas", "San Pascual", "Santa Teresita", "Santo Tomas", "Taal", "Talisay", "Tanauan", "Taysan", "Tingloy", "Tuy"],
      "Cavite": ["Alfonso", "Amadeo", "Bacoor", "Carmona", "Cavite City", "Dasmariñas", "General Emilio Aguinaldo", "General Mariano Alvarez", "General Trias", "Imus", "Indang", "Kawit", "Magallanes", "Maragondon", "Mendez", "Naic", "Noveleta", "Rosario", "Silang", "Tagaytay", "Tanza", "Ternate", "Trece Martires", "Gen. Trias"],
      "Laguna": ["Alaminos", "Bay", "Biñan", "Cabuyao", "Calamba", "Calauan", "Cavinti", "Famy", "Kalayaan", "Liliw", "Los Baños", "Luisiana", "Lumban", "Mabitac", "Magdalena", "Majayjay", "Nagcarlan", "Paete", "Pagsanjan", "Pakil", "Pangil", "Pila", "Rizal", "San Pablo", "San Pedro", "Santa Cruz", "Santa Maria", "Santa Rosa", "Siniloan", "Victoria"],
      "Quezon": ["Agdangan", "Alabat", "Atimonan", "Buenavista", "Burdeos", "Calauag", "Candelaria", "Catanauan", "Dolores", "General Luna", "General Nakar", "Guinayangan", "Gumaca", "Infanta", "Jomalig", "Lopez", "Lucban", "Lucena", "Macalelon", "Mauban", "Mulanay", "Padre Burgos", "Pagbilao", "Panukulan", "Patnanungan", "Perez", "Pitogo", "Plaridel", "Polillo", "Quezon", "Real", "Sampaloc", "San Andres", "San Antonio", "San Francisco", "San Narciso", "Sariaya", "Tagkawayan", "Tayabas", "Tiaong", "Unisan"],
      "Rizal": ["Angono", "Antipolo", "Baras", "Binangonan", "Cainta", "Cardona", "Jalajala", "Morong", "Pililla", "Rodriguez", "San Mateo", "Tanay", "Taytay", "Teresa"]
    },
    "Region IV-B - MIMAROPA": {
      "Marinduque": ["Boac", "Buenavista", "Gasan", "Mogpog", "Santa Cruz", "Torrijos"],
      "Occidental Mindoro": ["Abra de Ilog", "Calintaan", "Looc", "Lubang", "Magsaysay", "Mamburao", "Paluan", "Rizal", "Sablayan", "San Jose", "Santa Cruz"],
      "Oriental Mindoro": ["Baco", "Bansud", "Bongabong", "Bulalacao", "Calapan", "Gloria", "Mansalay", "Naujan", "Pinamalayan", "Pola", "Puerto Galera", "Roxas", "San Teodoro", "Socorro", "Victoria"],
      "Palawan": ["Aborlan", "Agutaya", "Araceli", "Balabac", "Bataraza", "Brooke's Point", "Busuanga", "Cagayancillo", "Coron", "Culion", "Cuyo", "Dumaran", "El Nido", "Kalayaan", "Linapacan", "Magsaysay", "Narra", "Puerto Princesa", "Quezon", "Rizal", "Roxas", "San Vicente", "Sofronio Española", "Taytay"],
      "Romblon": ["Alcantara", "Banton", "Cajidiocan", "Calatrava", "Concepcion", "Corcuera", "Ferrol", "Looc", "Magdiwang", "Odiongan", "Romblon", "San Agustin", "San Andres", "San Fernando", "San Jose", "Santa Fe", "Santa Maria"]
    },
    "Region V - Bicol Region": {
      "Albay": ["Bacacay", "Camalig", "Daraga", "Guinobatan", "Jovellar", "Legazpi", "Libon", "Ligao", "Malilipot", "Malinao", "Manito", "Oas", "Pio Duran", "Polangui", "Rapu-Rapu", "Santo Domingo", "Tabaco", "Tiwi"],
      "Camarines Norte": ["Basud", "Capalonga", "Daet", "Jose Panganiban", "Labo", "Mercedes", "Paracale", "San Lorenzo Ruiz", "San Vicente", "Santa Elena", "Talisay", "Vinzons"],
      "Camarines Sur": ["Baao", "Balatan", "Bato", "Bombon", "Buhi", "Bula", "Cabusao", "Calabanga", "Camaligan", "Canaman", "Caramoan", "Del Gallego", "Gainza", "Garchitorena", "Goa", "Iriga", "Lagonoy", "Libmanan", "Lupi", "Magarao", "Milaor", "Minalabac", "Nabua", "Naga", "Ocampo", "Pamplona", "Pasacao", "Pili", "Presentacion", "Ragay", "Sagñay", "San Fernando", "San Jose", "Sipocot", "Siruma", "Tigaon", "Tinambac"],
      "Catanduanes": ["Bagamanoc", "Baras", "Bato", "Caramoran", "Gigmoto", "Pandan", "Panganiban", "San Andres", "San Miguel", "Viga", "Virac"],
      "Masbate": ["Aroroy", "Baleno", "Balud", "Batuan", "Cataingan", "Cawayan", "Claveria", "Dimasalang", "Esperanza", "Mandaon", "Masbate", "Milagros", "Mobo", "Monreal", "Palanas", "Pio V. Corpuz", "Placer", "San Fernando", "San Jacinto", "San Pascual", "Uson"],
      "Sorsogon": ["Barcelona", "Bulan", "Bulusan", "Casiguran", "Castilla", "Donsol", "Gubat", "Irosin", "Juban", "Magallanes", "Matnog", "Pilar", "Prieto Diaz", "Santa Magdalena", "Sorsogon City"]
    },
    "NCR - National Capital Region": {
      "Caloocan": ["Caloocan City"],
      "Las Piñas": ["Las Piñas City"],
      "Makati": ["Makati City"],
      "Malabon": ["Malabon City"],
      "Mandaluyong": ["Mandaluyong City"],
      "Manila": ["Manila City"],
      "Marikina": ["Marikina City"],
      "Muntinlupa": ["Muntinlupa City"],
      "Navotas": ["Navotas City"],
      "Parañaque": ["Parañaque City"],
      "Pasay": ["Pasay City"],
      "Pasig": ["Pasig City"],
      "Quezon City": ["Quezon City"],
      "San Juan": ["San Juan City"],
      "Taguig": ["Taguig City"],
      "Valenzuela": ["Valenzuela City"],
      "Pateros": ["Pateros"]
    },
    "Region VI - Western Visayas": {
      "Aklan": ["Altavas", "Balete", "Banga", "Batan", "Buruanga", "Ibajay", "Kalibo", "Lezo", "Libacao", "Madalag", "Makato", "Malay", "Malinao", "Nabas", "New Washington", "Numancia", "Tangalan"],
      "Antique": ["Anini-y", "Barbaza", "Belison", "Bugasong", "Caluya", "Culasi", "Hamtic", "Laua-an", "Libertad", "Pandan", "Patnongon", "San Jose", "San Remigio", "Sebaste", "Sibalom", "Tibiao", "Tobias Fornier", "Valderrama"],
      "Capiz": ["Cuartero", "Dao", "Dumalag", "Dumarao", "Ivisan", "Jamindan", "Ma-ayon", "Mambusao", "Panay", "Panitan", "Pilar", "Pontevedra", "President Roxas", "Roxas City", "Sapian", "Sigma", "Tapaz"],
      "Guimaras": ["Buenavista", "Jordan", "Nueva Valencia", "San Lorenzo", "Sibunag"],
      "Iloilo": ["Ajuy", "Alimodian", "Anilao", "Badiangan", "Balasan", "Banate", "Barotac Nuevo", "Barotac Viejo", "Batad", "Bingawan", "Cabatuan", "Calinog", "Carles", "Concepcion", "Dingle", "Dueñas", "Dumangas", "Estancia", "Guimbal", "Igbaras", "Iloilo City", "Janiuay", "Lambunao", "Leganes", "Lemery", "Leon", "Maasin", "Miagao", "Mina", "New Lucena", "Oton", "Passi", "Pavia", "Pototan", "San Dionisio", "San Enrique", "San Joaquin", "San Miguel", "San Rafael", "Santa Barbara", "Sara", "Tigbauan", "Tubungan", "Zarraga"],
      "Negros Occidental": ["Bacolod City", "Bago City", "Binalbagan", "Cadiz City", "Calatrava", "Candoni", "Cauayan", "Enrique B. Magalona", "Escalante City", "Himamaylan City", "Hinigaran", "Hinoba-an", "Ilog", "Isabela", "Kabankalan City", "La Carlota City", "La Castellana", "Manapla", "Moises Padilla", "Murcia", "Pontevedra", "Pulupandan", "Sagay City", "Salvador Benedicto", "San Carlos City", "San Enrique", "Silay City", "Sipalay City", "Talisay City", "Toboso", "Valladolid", "Victorias City"]
    },
    "Region VII - Central Visayas": {
      "Bohol": ["Alburquerque", "Alicia", "Anda", "Antequera", "Baclayon", "Balilihan", "Batuan", "Bien Unido", "Bilar", "Buenavista", "Calape", "Candijay", "Carmen", "Catigbian", "Clarin", "Corella", "Cortes", "Dagohoy", "Danao", "Dauis", "Dimiao", "Duero", "Garcia Hernandez", "Getafe", "Guindulman", "Inabanga", "Jagna", "Lila", "Loay", "Loboc", "Loon", "Mabini", "Maribojoc", "Panglao", "Pilar", "President Carlos P. Garcia", "Sagbayan", "San Isidro", "San Miguel", "Sevilla", "Sierra Bullones", "Sikatuna", "Tagbilaran City", "Talibon", "Trinidad", "Tubigon", "Ubay", "Valencia"],
      "Cebu": ["Alcantara", "Alcoy", "Alegria", "Aloguinsan", "Argao", "Asturias", "Badian", "Balamban", "Bantayan", "Barili", "Bogo City", "Boljoon", "Borbon", "Carcar City", "Carmen", "Catmon", "Cebu City", "Compostela", "Consolacion", "Cordova", "Daanbantayan", "Dalaguete", "Danao City", "Dumanjug", "Ginatilan", "Lapu-Lapu City", "Liloan", "Madridejos", "Malabuyoc", "Mandaue City", "Medellin", "Minglanilla", "Moalboal", "Naga City", "Oslob", "Pilar", "Pinamungajan", "Poro", "Ronda", "Samboan", "San Fernando", "San Francisco", "San Remigio", "Santa Fe", "Santander", "Sibonga", "Sogod", "Tabogon", "Tabuelan", "Talisay City", "Toledo City", "Tuburan", "Tudela"],
      "Negros Oriental": ["Amlan", "Ayungon", "Bacong", "Bais City", "Basay", "Bayawan City", "Bindoy", "Canlaon City", "Dauin", "Dumaguete City", "Guihulngan City", "Jimalalud", "La Libertad", "Mabinay", "Manjuyod", "Pamplona", "San Jose", "Santa Catalina", "Siaton", "Sibulan", "Tanjay City", "Tayasan", "Valencia", "Vallehermoso", "Zamboanguita"],
      "Siquijor": ["Enrique Villanueva", "Larena", "Lazi", "Maria", "San Juan", "Siquijor"]
    },
    "Region VIII - Eastern Visayas": {
      "Biliran": ["Almeria", "Biliran", "Cabucgayan", "Caibiran", "Culaba", "Kawayan", "Maripipi", "Naval"],
      "Eastern Samar": ["Arteche", "Balangiga", "Balangkayan", "Borongan City", "Can-avid", "Dolores", "General MacArthur", "Giporlos", "Guiuan", "Hernani", "Jipapad", "Lawaan", "Llorente", "Maslog", "Maydolong", "Mercedes", "Oras", "Quinapondan", "Salcedo", "San Julian", "San Policarpo", "Sulat", "Taft"],
      "Leyte": ["Abuyog", "Alangalang", "Albuera", "Babatngon", "Barugo", "Bato", "Baybay City", "Burauen", "Calubian", "Capoocan", "Carigara", "Dagami", "Dulag", "Hilongos", "Hindang", "Inopacan", "Isabel", "Jaro", "Javier", "Julita", "Kananga", "La Paz", "Leyte", "MacArthur", "Mahaplag", "Matag-ob", "Matalom", "Mayorga", "Merida", "Ormoc City", "Palo", "Palompon", "Pastrana", "San Isidro", "San Miguel", "Santa Fe", "Tabango", "Tabontabon", "Tacloban City", "Tanauan", "Tolosa", "Tunga", "Villaba"],
      "Northern Samar": ["Allen", "Biri", "Bobon", "Capul", "Catarman", "Catubig", "Gamay", "Laoang", "Lapinig", "Las Navas", "Lavezares", "Lope de Vega", "Mapanas", "Mondragon", "Palapag", "Pambujan", "Rosario", "San Antonio", "San Isidro", "San Jose", "San Roque", "San Vicente", "Silvino Lobos", "Victoria"],
      "Samar": ["Almagro", "Basey", "Calbayog City", "Calbiga", "Catbalogan City", "Daram", "Gandara", "Hinabangan", "Jiabong", "Marabut", "Matuguinao", "Motiong", "Pagsanghan", "Paranas", "Pinabacdao", "San Jorge", "San Jose de Buan", "San Sebastian", "Santa Margarita", "Santa Rita", "Santo Niño", "Tagapul-an", "Talalora", "Tarangnan", "Villareal", "Zumarraga"],
      "Southern Leyte": ["Anahawan", "Bontoc", "Hinunangan", "Hinundayan", "Libagon", "Liloan", "Limasawa", "Maasin City", "Macrohon", "Malitbog", "Padre Burgos", "Pintuyan", "Saint Bernard", "San Francisco", "San Juan", "Silago", "Sogod", "Tomas Oppus"]
    },
    "Region IX - Zamboanga Peninsula": {
      "Zamboanga del Norte": ["Baliguian", "Dapitan City", "Dipolog City", "Godod", "Gutalac", "Jose Dalman", "Kalawit", "Katipunan", "La Libertad", "Labason", "Liloy", "Manukan", "Mutia", "Piñan", "Polanco", "Pres. Manuel A. Roxas", "Rizal", "Salug", "Sergio Osmeña Sr.", "Siayan", "Sibuco", "Sibutad", "Sindangan", "Siocon", "Sirawai", "Tampilisan"],
      "Zamboanga del Sur": ["Aurora", "Bayog", "Dimataling", "Dinas", "Dumalinao", "Dumingag", "Guipos", "Josefina", "Kumalarang", "Labangan", "Lakewood", "Lapuyan", "Mahayag", "Margosatubig", "Midsalip", "Molave", "Pagadian City", "Pitogo", "Ramon Magsaysay", "San Miguel", "San Pablo", "Sominot", "Tabina", "Tambulig", "Tigbao", "Tukuran", "Vincenzo A. Sagun", "Zamboanga City"],
      "Zamboanga Sibugay": ["Alicia", "Buug", "Diplahan", "Imelda", "Ipil", "Kabasalan", "Mabuhay", "Malangas", "Naga", "Olutanga", "Payao", "Roseller Lim", "Siay", "Talusan", "Titay", "Tungawan"]
    },
    "Region X - Northern Mindanao": {
      "Bukidnon": ["Baungon", "Cabanglasan", "Damulog", "Dangcagan", "Don Carlos", "Impasug-ong", "Kadingilan", "Kalilangan", "Kibawe", "Kitaotao", "Lantapan", "Libona", "Malaybalay City", "Malitbog", "Manolo Fortich", "Maramag", "Pangantucan", "Quezon", "San Fernando", "Sumilao", "Talakag", "Valencia City"],
      "Camiguin": ["Catarman", "Guinsiliban", "Mahinog", "Mambajao", "Sagay"],
      "Lanao del Norte": ["Bacolod", "Baloi", "Baroy", "Iligan City", "Kapatagan", "Kauswagan", "Kolambugan", "Lala", "Linamon", "Magsaysay", "Maigo", "Matungao", "Munai", "Nunungan", "Pantao Ragat", "Pantar", "Poona Piagapo", "Salvador", "Sapad", "Sultan Naga Dimaporo", "Tagoloan", "Tangcal", "Tubod"],
      "Misamis Occidental": ["Aloran", "Baliangao", "Bonifacio", "Calamba", "Clarin", "Concepcion", "Don Victoriano Chiongbian", "Jimenez", "Lopez Jaena", "Oroquieta City", "Ozamiz City", "Panaon", "Plaridel", "Sapang Dalaga", "Sinacaban", "Tangub City", "Tudela"],
      "Misamis Oriental": ["Alubijid", "Balingasag", "Balingoan", "Binuangan", "Cagayan de Oro City", "Claveria", "El Salvador City", "Gingoog City", "Gitagum", "Initao", "Jasaan", "Kinoguitan", "Lagonglong", "Laguindingan", "Libertad", "Lugait", "Magsaysay", "Manticao", "Medina", "Naawan", "Opol", "Salay", "Sugbongcogon", "Tagoloan", "Talisayan", "Villanueva"]
    },
    "Region XI - Davao Region": {
      "Davao del Norte": ["Asuncion", "Braulio E. Dujali", "Carmen", "Kapalong", "New Corella", "Panabo City", "Samal City", "San Isidro", "Santo Tomas", "Tagum City", "Talaingod"],
      "Davao del Sur": ["Bansalan", "Davao City", "Digos City", "Hagonoy", "Kiblawan", "Magsaysay", "Malalag", "Matanao", "Padada", "Santa Cruz", "Sulop"],
      "Davao Oriental": ["Baganga", "Banaybanay", "Boston", "Caraga", "Cateel", "Governor Generoso", "Lupon", "Manay", "Mati City", "San Isidro", "Tarragona"],
      "Davao de Oro": ["Compostela", "Laak", "Mabini", "Maco", "Maragusan", "Mawab", "Monkayo", "Montevista", "Nabunturan", "New Bataan", "Pantukan"],
      "Davao Occidental": ["Don Marcelino", "Jose Abad Santos", "Malita", "Santa Maria", "Sarangani"]
    },
    "Region XII - SOCCSKSARGEN": {
      "Cotabato": ["Alamada", "Aleosan", "Antipas", "Arakan", "Banisilan", "Carmen", "Kabacan", "Kidapawan City", "Libungan", "Magpet", "Makilala", "Matalam", "Midsayap", "M'lang", "Pigcawayan", "Pikit", "President Roxas", "Tulunan"],
      "Sarangani": ["Alabel", "Glan", "Kiamba", "Maasim", "Maitum", "Malapatan", "Malungon"],
      "South Cotabato": ["Banga", "General Santos City", "Koronadal City", "Lake Sebu", "Norala", "Polomolok", "Santo Niño", "Surallah", "T'boli", "Tampakan", "Tantangan", "Tupi"],
      "Sultan Kudarat": ["Bagumbayan", "Columbio", "Esperanza", "Isulan", "Kalamansig", "Lambayong", "Lebak", "Lutayan", "Palimbang", "President Quirino", "Sen. Ninoy Aquino", "Tacurong City"]
    },
    "Region XIII - Caraga": {
      "Agusan del Norte": ["Buenavista", "Butuan City", "Cabadbaran City", "Carmen", "Jabonga", "Kitcharao", "Las Nieves", "Magallanes", "Nasipit", "Remedios T. Romualdez", "Santiago", "Tubay"],
      "Agusan del Sur": ["Bayugan City", "Bunawan", "Esperanza", "La Paz", "Loreto", "Prosperidad", "Rosario", "San Francisco", "San Luis", "Santa Josefa", "Sibagat", "Talacogon", "Trento", "Veruela"],
      "Dinagat Islands": ["Basilisa", "Cagdianao", "Dinagat", "Libjo", "Loreto", "San Jose", "Tubajon"],
      "Surigao del Norte": ["Alegria", "Bacuag", "Burgos", "Claver", "Dapa", "Del Carmen", "General Luna", "Gigaquit", "Mainit", "Malimono", "Pilar", "Placer", "San Benito", "San Francisco", "San Isidro", "Santa Monica", "Sison", "Socorro", "Surigao City", "Tagana-an", "Tubod"],
      "Surigao del Sur": ["Barobo", "Bayabas", "Bislig City", "Cagwait", "Cantilan", "Carmen", "Carrascal", "Cortes", "Hinatuan", "Lanuza", "Lianga", "Lingig", "Madrid", "Marihatag", "San Agustin", "San Miguel", "Tagbina", "Tago", "Tandag City"]
    },
    "BARMM - Bangsamoro Autonomous Region in Muslim Mindanao": {
      "Basilan": ["Akbar", "Al-Barka", "Hadji Mohammad Ajul", "Isabela City", "Lamitan City", "Lantawan", "Maluso", "Sumisip", "Tabuan-Lasa", "Tipo-Tipo", "Tuburan", "Ungkaya Pukan"],
      "Lanao del Sur": ["Bacolod-Kalawi", "Balabagan", "Balindong", "Bayang", "Binidayan", "Buadiposo-Buntong", "Bubong", "Bumbaran", "Butig", "Calanogas", "Ditsaan-Ramain", "Ganassi", "Kapai", "Kapatagan", "Lumba-Bayabao", "Lumbaca-Unayan", "Lumbatan", "Lumbayanague", "Madalum", "Madamba", "Maguing", "Malabang", "Marantao", "Marawi City", "Marogong", "Masiu", "Mulondo", "Pagayawan", "Piagapo", "Poona Bayabao", "Pualas", "Saguiaran", "Sultan Dumalondong", "Picong", "Tagoloan II", "Tamparan", "Taraka", "Tubaran", "Tugaya", "Wao"],
      "Maguindanao del Norte": ["Barira", "Buldon", "Datu Blah T. Sinsuat", "Datu Odin Sinsuat", "Kabuntalan", "Matanog", "Northern Kabuntalan", "Parang", "Sultan Kudarat", "Sultan Mastura", "Upi"],
      "Maguindanao del Sur": ["Ampatuan", "Buluan", "Datu Abdullah Sangki", "Datu Anggal Midtimbang", "Datu Hoffer Ampatuan", "Datu Montawal", "Datu Paglas", "Datu Piang", "Datu Salibo", "Datu Saudi Ampatuan", "Datu Unsay", "Gen. Salipada K. Pendatun", "Guindulungan", "Mamasapano", "Mangudadatu", "Pagalungan", "Paglat", "Pandag", "Rajah Buayan", "Shariff Aguak", "Shariff Saydona Mustapha", "South Upi", "Sultan sa Barongis", "Talayan", "Talitay", "Yumol"],
      "Sulu": ["Banguingui", "Hadji Panglima Tahil", "Indanan", "Jolo", "Kalingalan Caluang", "Lugus", "Luuk", "Maimbung", "Old Panamao", "Omar", "Pandami", "Panglima Estino", "Pangutaran", "Parang", "Pata", "Patikul", "Siasi", "Talipao", "Tapul"],
      "Tawi-Tawi": ["Bongao", "Languyan", "Mapun", "Panglima Sugala", "Sapa-Sapa", "Sibutu", "Simunul", "Sitangkai", "South Ubian", "Tandubas", "Turtle Islands"]
    }
  };

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    regions = addressData.keys.toList();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    brgyController.dispose();
    super.dispose();
  }
  
  // update provinces based on selected region
  void _updateProvinces(String? region) {
    setState(() {
      if (region != null && addressData.containsKey(region)) {
        provinces = addressData[region]!.keys.toList();
        selectedProvince = null;
        selectedCity = null;
        cities = [];
      } else {
        provinces = [];
        selectedProvince = null;
        selectedCity = null;
        cities = [];
      }
    });
  }

  // update cities based on selected province
  void _updateCities(String? province) {
    setState(() {
      if (province != null && selectedRegion != null && 
          addressData.containsKey(selectedRegion) &&
          addressData[selectedRegion]!.containsKey(province)) {
        cities = addressData[selectedRegion]![province]!;
        selectedCity = null;
      } else {
        cities = [];
        selectedCity = null;
      }
    });
  }

  // addresses of the user
  Future<void> _fetchAddresses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/mbuyer_addresses/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            addresses = List<Map<String, dynamic>>.from(data['addresses']);
            isLoading = false;
          });
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load addresses';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load addresses';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _showEditModal(Map<String, dynamic> address) {
    nameController.text = address['add_name'] ?? '';
    phoneController.text = '+63 ${address['add_num'] ?? ''}';
    brgyController.text = address['brgy'] ?? '';

    String? currentRegion = address['region'];
    String? currentProvince = address['province'];
    String? currentCity = address['city'];

    List<String> initialProvinces = [];
    List<String> initialCities = [];

    if (currentRegion != null && addressData.containsKey(currentRegion)) {
      initialProvinces = addressData[currentRegion]!.keys.toList();
      if (currentProvince != null && addressData[currentRegion]!.containsKey(currentProvince)) {
        initialCities = addressData[currentRegion]![currentProvince]!;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButton<String>(
                      value: currentRegion,
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Select a region'),
                      items: regions.map((String region) {
                        return DropdownMenuItem<String>(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          currentRegion = newValue;
                          currentProvince = null;
                          currentCity = null;
                          if (newValue != null && addressData.containsKey(newValue)) {
                            initialProvinces = addressData[newValue]!.keys.toList();
                            initialCities = [];
                          } else {
                            initialProvinces = [];
                            initialCities = [];
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Province',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButton<String>(
                      value: currentProvince,
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Select a province'),
                      items: initialProvinces.map((String province) {
                        return DropdownMenuItem<String>(
                          value: province,
                          child: Text(province),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          currentProvince = newValue;
                          currentCity = null;
                          if (newValue != null && currentRegion != null && 
                              addressData.containsKey(currentRegion) &&
                              addressData[currentRegion]!.containsKey(newValue)) {
                            initialCities = addressData[currentRegion]![newValue]!;
                          } else {
                            initialCities = [];
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'City/Municipality',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButton<String>(
                      value: currentCity,
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Select a city/municipality'),
                      items: initialCities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          currentCity = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: brgyController,
                    decoration: const InputDecoration(
                      labelText: 'House No., Street, Barangay',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (currentRegion == null || currentProvince == null || currentCity == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select region, province, and city')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _updateAddress(address['add_id'], currentRegion!, currentProvince!, currentCity!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B4BB5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // update edited address
  Future<void> _updateAddress(int addId, String region, String province, String city) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/mbuyer_addresses/${widget.userId}/$addId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'add_name': nameController.text,
          'add_num': phoneController.text.replaceAll('+63 ', ''),
          'region': region,
          'province': province,
          'city': city,
          'brgy': brgyController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully')),
        );
        _fetchAddresses();
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update address')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // footer buttons
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userId: widget.userId)),
      );
    }
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NotificationsPage(userId: widget.userId)),
      );
    }
    else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/LOGO.png',
          height: 55,
          width: 100,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(icon: Image.asset('assets/images/cart.png',width: 30,height: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage(userId: widget.userId)),
              );
            },
          ),
          IconButton(icon: Image.asset('assets/images/message.png', width: 30, height: 30),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Image.asset('assets/images/home.png',width: 35, height: 35), label: 'Home'),
          BottomNavigationBarItem(icon: Image.asset('assets/images/notifs.png', width: 35, height: 35), label: 'Notifications'),
          BottomNavigationBarItem(icon: Image.asset('assets/images/blue_user.png', width: 35, height: 35), label: 'Profile'),
        ],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF4B4BB5)),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'My Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Color(0xFF888888)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ToApproveOrders(userId: widget.userId),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset('assets/images/to_approve.png', width: 70, height: 70),
                            Text("To Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF292D32))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ToShipOrders(userId: widget.userId),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset('assets/images/to_ship.png', width: 70, height: 70),
                            Text("To Ship", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF292D32))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ToReceiveOrders(userId: widget.userId),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset('assets/images/to_receive.png', width: 70, height: 70),
                            Text("To Receive", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF292D32))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                const Text(
                  'My Addresses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (error.isNotEmpty)
                  Center(child: Text(error, style: TextStyle(color: Colors.red)))
                else if (addresses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF888888)),
                    ),
                    child: const Center(
                      child: Text(
                        'No addresses found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...addresses.map((address) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GestureDetector(
                      onTap: () => _showEditModal(address),
                      child: _buildAddressCard(
                        address['add_name'] ?? 'No name',
                        '+63 ${address['add_num'] ?? 'No number'}',
                        '${address['brgy'] ?? ''}, ${address['city'] ?? ''}, ${address['province'] ?? ''}, ${address['region'] ?? ''}',
                      ),
                    ),
                  )).toList(),

                const SizedBox(height: 60),

                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                // const SizedBox(height: 12),
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(12),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.grey.withOpacity(0.1),
                //         spreadRadius: 1,
                //         blurRadius: 5,
                //       ),
                //     ],
                //   ),
                //   child: Column(
                //     children: [
                //       ListTile(
                //         leading: const Icon(Icons.person_outline),
                //         title: const Text('Edit Profile'),
                //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                //         onTap: () {},
                //       ),
                //       ListTile(
                //         leading: const Icon(Icons.settings_outlined),
                //         title: const Text('Settings'),
                //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                //         onTap: () {},
                //       ),
                //       ListTile(
                //         leading: const Icon(Icons.help_outline),
                //         title: const Text('Help Center'),
                //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                //         onTap: () {},
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log Out'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [                            
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFFFFC4CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // addresses of user
  Widget _buildAddressCard(String name, String phone, String address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF888888)),                                  
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    phone,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.edit, color: Colors.grey[600], size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}