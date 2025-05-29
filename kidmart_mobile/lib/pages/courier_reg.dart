import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/constants.dart';

class CourierRegisterPage extends StatefulWidget {
  @override
  _CourierRegisterPageState createState() => _CourierRegisterPageState();
}

class _CourierRegisterPageState extends State<CourierRegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController middleInitialController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();
  File? _selectedImage;
  String? _imageName;

  String gender = 'Male';
  String selectedCountry = '';
  String selectedRegion = '';
  String selectedProvince = '';
  String selectedCity = '';
  List<String> provinceList = [];
  List<String> cityList = [];
  
  bool isAgreedToTerms = false;

  final Color buttonColor = const Color(0xFF4B4BB5);
  final Color textColor = Colors.white;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/reg_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Image.asset('assets/images/prod_back.png', width: 45, height: 45),
                  onPressed: () => Navigator.push(
                    context, MaterialPageRoute(
                      builder: (context) => LoginPage())),
                ),
              ),
              SizedBox(height: 10),

              Center(
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF202020),
                  ),
                ),
              ),

              SizedBox(height: 30),

              Text('Name:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                  hintText: 'Last Name',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                  hintText: 'First Name',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: middleInitialController, maxLength: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                  hintText: 'Middle Initial',
                ),
              ),

              SizedBox(height: 25),
              Text('Email:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                  hintText: "example@company.com"
                ),
              ),

              SizedBox(height: 25),
              Text('Gender:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  buildRadio('Male'),
                  buildRadio('Female'),
                  buildRadio('Others'),
                ],
              ),

              SizedBox(height: 15),
              Text('Birth Date:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextField(
                controller: birthDateController,
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      birthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                  hintText: 'Select Birth Date',
                ),
              ),

              SizedBox(height: 40),
              Text('Country:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  isEmpty: selectedCountry.isEmpty,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCountry.isEmpty ? null : selectedCountry,
                      hint: Text('Select Country'),
                      isExpanded: true,
                      onChanged: (val) {
                        if (val == 'Philippines (+63)') {
                          setState(() => selectedCountry = val!);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'America (+1)',
                          enabled: false,
                          child: Text('America (+1)', style: TextStyle(color: Colors.grey)),
                        ),
                        DropdownMenuItem(
                          value: 'Australia (+61)',
                          enabled: false,
                          child: Text('Australia (+61)', style: TextStyle(color: Colors.grey)),
                        ),
                        DropdownMenuItem(
                          value: 'Brazil (+55)',
                          enabled: false,
                          child: Text('Brazil (+55)', style: TextStyle(color: Colors.grey)),
                        ),
                        DropdownMenuItem(
                          value: 'Japan (+81)',
                          enabled: false,
                          child: Text('Japan (+81)', style: TextStyle(color: Colors.grey)),
                        ),
                        DropdownMenuItem(
                          value: 'Philippines (+63)',
                          enabled: true,
                          child: Text('Philippines (+63)'),
                        ),
                        DropdownMenuItem(
                          value: 'United Kingdom (+44)',
                          enabled: false,
                          child: Text('United Kingdom (+44)', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),
              Text('Mobile Number:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextField(
                controller: mobileController,
                maxLength: 10,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                    hintText: '999-999-9999',
                ),
              ),

              SizedBox(height: 15),
              Text('Region:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  isEmpty: selectedRegion.isEmpty,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRegion.isEmpty ? null : selectedRegion,
                      hint: Text('Select Region'),
                      isExpanded: true,
                      onChanged: (region) {
                        setState(() {
                          selectedRegion = region!;
                          provinceList = addressData[selectedRegion]!.keys.toList();
                          selectedProvince = '';
                          cityList = [];
                          selectedCity = '';
                        });
                      },
                      items: addressData.keys
                          .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                          .toList(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),
              Text('Province:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  isEmpty: selectedProvince.isEmpty,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provinceList.contains(selectedProvince) ? selectedProvince : null,
                      hint: Text('Select Province'),
                      isExpanded: true,
                      onChanged: (province) {
                        setState(() {
                          selectedProvince = province!;
                          cityList = addressData[selectedRegion]![selectedProvince]!;
                          selectedCity = '';
                        });
                      },
                      items: provinceList
                          .map((province) => DropdownMenuItem(value: province, child: Text(province)))
                          .toList(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),
              Text('City/Municipality:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                  isEmpty: selectedCity.isEmpty,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: cityList.contains(selectedCity) ? selectedCity : null,
                      hint: Text('Select City/Municipality'),
                      isExpanded: true,
                      onChanged: (city) {
                        setState(() {
                          selectedCity = city!;
                        });
                      },
                      items: cityList
                          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),
              Text('House No., Street, Barangay:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextField(
                controller: houseNumberController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                ),
              ),

              SizedBox(height: 40),
              Text('Upload Driver\'s License:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ElevatedButton(
                onPressed: () async {
                  final result = await imagePicker.pickImage(source: ImageSource.gallery);
                  if (result != null) {
                    setState(() {
                      _selectedImage = File(result.path);
                      _imageName = result.name;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFaaaaaa),
                  padding: EdgeInsets.symmetric(horizontal: 115, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(_selectedImage != null ? 'Change License' : 'Upload License', style: TextStyle(fontSize: 16, color: textColor)),
              ),
              if (_selectedImage != null) ...[
                SizedBox(height: 10),
                Text('Selected: $_imageName', style: TextStyle(fontSize: 16)),
              ],

              SizedBox(height: 40),
              Text('Password:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextField(
                controller: passwordController,
                maxLength: 20,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                  hintText: '20 maximum characters',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                maxLength: 20,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                  hintText: 'Confirm Password',
                ),
              ),

              SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: isAgreedToTerms,
                    onChanged: (val) => setState(() => isAgreedToTerms = val!),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Color(0xFF202020), fontFamily: 'Poppins'),
                        children: [
                          TextSpan(text: 'I have read and agreed to the '),
                          TextSpan(
                            text: 'terms and conditions',
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isAgreedToTerms) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Terms Required'),
                          content: Text('You must agree to the terms and conditions.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (lastNameController.text.isEmpty ||
                        firstNameController.text.isEmpty ||
                        middleInitialController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        selectedCountry.isEmpty ||
                        mobileController.text.isEmpty ||
                        selectedRegion.isEmpty ||
                        selectedProvince.isEmpty ||
                        selectedCity.isEmpty ||
                        houseNumberController.text.isEmpty ||
                        passwordController.text.isEmpty ||
                        _selectedImage == null ||
                        birthDateController.text.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Missing Fields'),
                          content: Text('Please fill in all required fields and upload your driver\'s license.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (passwordController.text.length < 8) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Password Too Short'),
                          content: Text('Password must be at least 8 characters.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (passwordController.text != confirmPasswordController.text) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Password Mismatch'),
                          content: Text('Passwords do not match.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    var request = http.MultipartRequest(
                      'POST',
                      Uri.parse('${ApiConstants.baseUrl}/mcourier_register'),
                    );

                    request.fields['lname'] = lastNameController.text.trim();
                    request.fields['fname'] = firstNameController.text.trim();
                    request.fields['mname'] = middleInitialController.text.trim();
                    request.fields['email'] = emailController.text.trim();
                    request.fields['gender'] = gender;
                    request.fields['country'] = selectedCountry;
                    request.fields['number'] = mobileController.text.trim();
                    request.fields['password'] = passwordController.text.trim();
                    request.fields['region'] = selectedRegion;
                    request.fields['province'] = selectedProvince;
                    request.fields['city'] = selectedCity;
                    request.fields['brgy'] = houseNumberController.text.trim();
                    request.fields['birth'] = birthDateController.text.trim();

                    if (_selectedImage != null) {
                      request.files.add(
                        await http.MultipartFile.fromPath(
                          'drivers_license',
                          _selectedImage!.path,
                        ),
                      );
                    }

                    try {
                      var response = await request.send();
                      var responseData = await response.stream.bytesToString();
                      var data = jsonDecode(responseData);
                      
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(data['status'] == 'success' ? 'Success' : 'Error'),
                          content: Text(data['message'] ?? 'Registration failed.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                if (data['status'] == 'success') {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => LoginPage()),
                                    (route) => false,
                                  );
                                }
                              },
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Error'),
                          content: Text('Failed to connect to the server. Please try again.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text('Register', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRadio(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: gender,
          onChanged: (val) => setState(() => gender = val!),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      ],
    );
  }
}