import type { Dict } from "./en";

// Turkish, polite "siz" like the app. Labels match lib/l10n/app_tr.arb and One Recorder's values-tr.
export const tr: Dict = {
  meta: {
    title: "One Dialer · Android için telefon ve arama engelleyici",
    description: "Arama engelleme, çift SIM ve buzlu cam tasarımıyla hızlı T9 çevirici.",
    released: "Google Play'de ücretsiz.",
    beta: "Şimdi Google Play'de kapalı betada.",
    recorderTitle: "One Recorder · One Dialer",
    recorderDescription: "Aramalarınızı One Dialer'da, bu siteden yüklediğiniz küçük bir yardımcı uygulama olan One Recorder ile kaydedin. Nasıl kurulur ve neler beklenir.",
  },
  nav: {
    label: "Site",
    whatsNew: "Yenilikler",
    recorder: "Recorder",
    privacy: "Gizlilik",
    getApp: "Uygulamayı al",
    joinBeta: "Betaya katıl",
    beta: "Beta",
  },
  stage: {
    headline: ["Aramalar,", "cam", "gibi."],
    intro: "Android için hızlı ve gizli bir telefon uygulaması. Akıllı T9, arama engelleme ve çift SIM, tam siyah üzerinde.",
    small: "Ücretsiz · Reklamsız · Android 10 ve üstü",
    screens: "Ekranlar",
    alt: "One Dialer'da {title} ekranı",
  },
  screens: [
    { title: "Tuşlar", body: "Aramalarınızın üzerinde buzlu tuşlar ve her SIM için bir arama tuşu." },
    { title: "Aramalar", body: "Cevapsızlar kırmızı, tekrarlananlar gruplu, engellenenler işaretli. Tuş takımı bir dokunuş uzakta." },
    { title: "Kişiler", body: "Önce favoriler, sonra başparmağınızın altında A–Z dizini." },
    { title: "Gelen", body: "Tam ekran, arayanın renkleriyle, doğrudan kilit ekranında." },
    { title: "Görüşme", body: "Sessiz, beklet, hoparlör ve tuş takımı için büyük cam düğmeler." },
  ],
  does: {
    h: "Ne yapar.",
    h2: "Ve ne yapmaz.",
    items: [
      { title: "Çalmadan engeller", text: "Gizli numaralar, bilinmeyen arayanlar veya kişilerinizde olmayan herkes. Telefonunuzun kendi engel listesi de dahil." },
      { title: "Çift SIM, doğru yapılmış", text: "Her kişi için bir SIM, varsayılan bir SIM ya da her seferinde sor. Arama tuşu hangi SIM'de olduğunuzu gösterir." },
      { title: "Gerçek bir telefon uygulaması", text: "Her arama Android'in kendi Telecom altyapısından geçer, yani aramalar tam olarak sistem çeviricisindeki gibi davranır." },
      { title: "Telefonunuzda kalır", text: "Hesap yok, reklam yok. Aramalarınız ve kişileriniz cihazdan hiç çıkmaz." },
      { title: "Açık kaynak", text: "GPL-3.0. Kodu okuyun, hata bildirin veya kendi dilinizi ekleyin." },
    ],
    github: "GitHub'da One Dialer",
  },
  smooth: {
    h: "Her telefonda",
    h2: "akıcı.",
    text: "İlk açılışta One Dialer telefonunuzun çipini okur ve bir görsel efekt seviyesi seçer; bunu Ayarlar'dan değiştirebilirsiniz. Üç seviyeyi burada deneyin: bu sayfanın camı, tuş takımı ve üstteki levha dahil, seçiminizi izler.",
  },
  levels: {
    label: "Görsel efektler",
    full: { label: "Tümü", text: "Kenarı parlayan buzlu arama camı. Amiral gemisi çipler buradan başlar." },
    reduced: { label: "Azaltılmış", text: "Tek bir ortak bulanıklığın üzerinde düz, yarı saydam bir dolgu. Orta seviye çipler buradan başlar." },
    off: { label: "Kapalı", text: "Düz dolgular, hiç bulanıklık yok. Giriş seviyesi çipler ve az belleği olan telefonlar buradan başlar." },
  },
  keypad: {
    hint: "Tuşlarda 3662'yi deneyin",
    none: "Bu ad veya numarayla kimse yok.",
    delete: "Sil",
  },
  whatsNew: {
    h: "Yenilikler.",
    beta: "Beta {n}",
    version: "Sürüm {v}",
    note: "Sürüm notları yalnızca İngilizcedir.",
  },
  get: {
    h: "One Dialer'ı edinin.",
    h2: "Google Play'de ücretsiz.",
    text: "Diğer uygulamalar gibi yükleyin, sorduğunda One Dialer'ı varsayılan telefon uygulamanız yapın. Android 10 ve üstü.",
  },
  join: {
    h: "Betaya katılın.",
    h2: "İki adım.",
    text: "One Dialer, Google Play'de kapalı testte. Test grubuna katılın, sonra diğer uygulamalar gibi Play'den yükleyin.",
    step: "Adım {n}: ",
    group: {
      title: "Google Grubu'na katılın",
      text: "Grubu açın ve Gruba katıl'a dokunun. Böylece Google hesabınız test kullanıcıları listesine girer.",
      note: "Telefonunuzun Play Store'unda oturum açtığınız Google hesabını kullanın.",
      cta: "Gruba katıl",
    },
    tester: {
      title: "Google Play'de test kullanıcısı olun",
      text: "Test sayfasını açın, Test kullanıcısı ol'a dokunun, ardından Google Play'den indirin ve yükleyin.",
      note: "Gruba katıldıktan sonra bu sayfanın sizi içeri alması birkaç dakika sürebilir.",
      cta: "Test kullanıcısı ol",
    },
  },
  apk: {
    title: "One Dialer'ı APK dosyası olarak mı aldınız?",
    text: "Dosya olarak paylaşılan ya da başka bir uygulamayla telefondan çıkarılan kopyalar resmi değildir. Güncelleme almazlar ve değiştirilmiş olabilirler.",
    released: "Kaldırın ve bunun yerine Google Play'den yükleyin.",
    beta: "Kaldırın ve bunun yerine buradan katılın.",
  },
  faq: {
    h: "Sorular,",
    h2: "yanıtlar.",
    items: [
      {
        beta: true,
        q: "Neden kapalı beta?",
        a: "Google Play, yeni uygulamaların herkese açılmadan önce bir grup kişi tarafından test edilmesini istiyor. Katılmanız One Dialer'ın oraya ulaşmasına yardım eder ve her güncellemeyi ilk siz alırsınız.",
      },
      {
        beta: true,
        q: "Play bağlantısı uygulamanın kullanılamadığını söylüyor.",
        a: "Google Grubu'na telefonunuzun Play Store'unda oturum açtığınız Google hesabıyla katıldığınızdan emin olun. Katıldıktan sonra test bağlantısının çalışması birkaç dakika sürebilir.",
      },
      { q: "Hangi telefonlarda çalışır?", a: "Android 10 veya üstü. Arama yapmak ve almak için, sorduğunda One Dialer'ı varsayılan telefon uygulamanız yapın." },
      { q: "Ücretsiz mi? Reklam var mı?", a: "Ücretsizdir ve reklam yoktur." },
      {
        q: "Aramalarım ve kişilerim telefonumdan çıkıyor mu?",
        a: "Hayır. Arama geçmişiniz ve kişileriniz telefonunuzda kalır. Gizlilik politikası, kilitlenme raporları gibi tam olarak neyin gönderildiğini listeler.",
      },
      {
        q: "One Dialer'ı APK dosyası olarak aldım.",
        a: "O kopya resmi değil: güncelleme almaz ve değiştirilmiş olabilir. Kaldırın, sonra One Dialer'ı Google Play'den yükleyin.",
        aBeta: "O kopya resmi değil: güncelleme almaz ve değiştirilmiş olabilir. Kaldırın, sonra Google Play'den almak için buradan betaya katılın.",
      },
      { beta: true, q: "Betadan nasıl ayrılırım?", a: "Google Play test bağlantısını açın ve Programdan ayrıl'ı seçin; isterseniz ardından uygulamayı kaldırın." },
    ],
  },
  play: "Google Play'den edinin",
  footer: {
    bug: "Hata mı buldunuz?",
    idea: "Bir fikriniz mi var?",
    feature: "Özellik iste",
    report: "Hata bildir",
    label: "Alt bilgi",
    recorder: "One Recorder",
    privacy: "Gizlilik politikası (İngilizce)",
    contact: "İletişim",
    language: "Dil",
  },
  recorder: {
    back: "One Dialer'a dön",
    title: "One Recorder",
    h1: "One",
    h1b: "Recorder.",
    lead: "One Dialer için arama kaydı. Ayrı bir uygulamadır, böylece Google Play'deki One Dialer kendisi hiçbir şey kaydetmez.",
    download: "APK'yı indir",
    downloadNote: "En son sürüm, GitHub Releases'tan · Android 12 veya üstü",
    prosTitle: "Neler sunar",
    pros: [
      "Aramanın iki tarafı da tam ses seviyesinde, Android 12 ve üstünde: siz ve karşı taraf; ahize, hoparlör, Bluetooth veya kulaklıkla. Root yok, bilgisayar yok, ayrı bir Shizuku uygulaması yok.",
      "Yeniden başlatmadan sonra Wi-Fi'a bağlanır bağlanmaz kendiliğinden yeniden başlar.",
      "Mikrofon izni ve erişilebilirlik hizmeti yok. One Recorder aramanın kendisini, yalnızca kaydettiğiniz bir arama sırasında kaydeder.",
      "Kayıtlar telefonunuzda kalır. Hiçbir şey yüklenmez; hesap ve reklam yoktur.",
      "İstediğiniz zaman ya da otomatik kaydedin: her arama, bilinmeyen numaralar veya yalnızca seçtiğiniz kişiler.",
      "Kayıtlarınız One Dialer'da; kişi adları, arama, yıldızlar, paylaşma ve otomatik silme ile.",
      "One Dialer gibi açık kaynak. Ne yaptığını herkes kontrol edebilir.",
    ],
    consTitle: "Neler beklenir",
    cons: [
      "İki tarafı kaydetmek için Geliştirici seçenekleri ve Kablosuz hata ayıklama bir kez açılmalı, her başlatmada da Wi-Fi gerekir. Yeniden başlatmadan sonra başlayamazsa (Wi-Fi yoksa ya da Geliştirici seçenekleri kapalıysa), One Recorder'da dokunarak başlatırsınız.",
      "Bazı bankacılık ve ödeme uygulamaları Geliştirici seçenekleri açıkken açılmaz.",
      "Bazı telefonlarda Wi-Fi araması üzerinden yapılan aramalarda yalnızca bir taraf kaydedilir. Bu, One Recorder'dan değil telefonun ses sürücüsünden kaynaklanır.",
      "Android 12 veya üstü gerekir. Android 10 ve 11, hizmeti Kablosuz hata ayıklama üzerinden başlatamaz ve orada kaydetmenin başka yolu yoktur.",
      "Kendini güncellemez. Google Play onu tanımaz, yeni sürümler için buraya dönersiniz.",
      "Yalnızca Google Play'den yüklenmiş One Dialer 1.0.0-beta.9 veya üstüyle çalışır, dosyadan yüklenmiş bir kopyayla çalışmaz.",
      "Karşı tarafa kayıt yaptığınız söylenmez. Bu sizin sorumluluğunuzdadır ve bazı yerlerde onayı olmadan yasaya aykırıdır.",
    ],
    setup: "Adım adım",
    setupB: "kurun.",
    toc: "Bu sayfada",
    intro: "Yaklaşık beş dakika, bir kez. Sonrasında One Dialer'ın arama ekranından kaydedersiniz ve One Recorder'ı bir daha açmazsınız.",
    sections: [
      {
        id: "before",
        title: "Başlamadan önce",
        blocks: [
          {
            ul: [
              "Android 12 veya üstü bir telefon; ilk kurulum için ve hizmet her başladığında Wi-Fi.",
              "**Google Play'den One Dialer**, sürüm 1.0.0-beta.9 veya üstü, varsayılan telefon uygulaması olarak. One Recorder resmi uygulamayla konuştuğunu kontrol eder ve diğerlerini yok sayar.",
              "Uygulama için birkaç megabayt boş alan ve kayıtlar için yer: arama dakikası başına yaklaşık yarım megabayt.",
            ],
          },
        ],
      },
      {
        id: "install",
        title: "Uygulamayı yükleyin",
        blocks: [
          {
            ol: [
              "Telefonunuzda bu sayfanın üstündeki **APK'yı indir**'e dokunun. Dosyanın adı `one-dialer-recorder.apk`.",
              "İndirme bildiriminden ya da Dosyalar uygulamanızın İndirilenler bölümünden açın.",
              "Android tarayıcınızın uygulama yüklemesine izin verilmediğini söylerse **Ayarlar**'a dokunun, **Bu kaynaktan izin ver**'i açın ve geri dönün.",
              "**Yükle**'ye dokunun. Uygulama Play'den gelmediği için Google Play Protect taramayı önerebilir. İzin verin; GitHub'da yayınlanan uygulamanın aynısıdır.",
            ],
          },
        ],
      },
      {
        id: "both",
        title: "İki tarafı da kaydedin",
        blocks: [
          { p: "One Recorder'ı açın: **İki tarafı da kaydet** en üstte; ilerledikçe her satır Hazır olur." },
          {
            ol: [
              "**Geliştirici seçenekleri.** Kapalıysa **Ayarlar › Telefon hakkında**'yı açın (bazı telefonlarda Telefon hakkında › Yazılım bilgileri) ve **Yapım numarası**'na yedi kez dokunun.",
              "**Kablosuz hata ayıklama ile eşleyin.** Satıra dokunun. One Recorder Geliştirici seçeneklerini açar ve bir bildirim gösterir. **Kablosuz hata ayıklama**'yı açın, içine girin ve **Eşleme koduyla cihaz eşle**'ye dokunun.",
              "Kodu ekranda tutun, One Recorder bildirimini aşağı çekin, **Kodu girin**'e dokunun ve altı haneyi yazın. One Recorder eşlenir ve hizmetini başlatır. Yalnızca bir kez eşlersiniz.",
              "**Kayıt hizmeti: hazır.** Çalışmıyor diyorsa Wi-Fi'da olduğunuzdan emin olun ve başlatmak için satıra dokunun. **Yeniden başlatmadan sonra başlat**, hizmet ilk kez başladığında kendiliğinden açılır.",
            ],
          },
          {
            p: "Kablosuz hata ayıklamayı yeniden kapatabilirsiniz: One Recorder hizmeti başlatması gerektiğinde onu bir anlığına açar, sonra yeniden kapatır. Telefonunuz Kablosuz hata ayıklama kapanınca hizmeti durduruyorsa One Recorder onu açık bırakır.",
          },
        ],
      },
      {
        id: "setup",
        title: "Bildirimler ve pil",
        blocks: [
          {
            ol: [
              "**Bildirimler.** Bir aramanın kaydedildiğini görebilmek için izin verin.",
              "**Pil: Kısıtlanmamış.** İsteğe bağlı ama önerilir. Telefonun, bir arama beklerken kaydediciyi kapatmasını önler.",
            ],
          },
        ],
      },
      {
        id: "record",
        title: "Bir aramayı kaydedin",
        blocks: [
          {
            ul: [
              "Arama sırasında One Dialer'ın arama ekranında **⋮ › Kaydet**'e dokunun. Durdurmak için yeniden dokunun. Arama bitince kayıt da kendiliğinden durur.",
              "İlk seferde One Dialer onay hakkında kısa bir bildirim gösterir. Kabul ettiğinizde kayıt başlar.",
              "Otomatik kaydetmek için One Dialer'da **Ayarlar › Arama kaydı**'nı açın. Otomatik kayıt kapalı olabilir ya da her aramayı, yalnızca bilinmeyen numaraları veya yalnızca seçtiğiniz kişileri kaydedebilir; **Asla kaydetme** listesi seçtiğiniz kişileri dışarıda tutar.",
            ],
          },
        ],
      },
      {
        id: "recordings",
        title: "Kayıtlarınız",
        blocks: [
          {
            p: "Onları One Dialer'da **Aramalar › ⋮ › Kayıtlar** altında ya da **Ayarlar › Arama kaydı**'nda bulursunuz. Kişinin adıyla güne göre gruplanırlar; arayabilir, filtreleyebilir (Tümü, Yıldızlı, Kişiler, Bilinmiyor), oynatabilir, yıldızlayabilir, yeniden adlandırabilir, paylaşabilir veya silebilirsiniz.",
          },
          {
            p: "Dosyalar One Recorder'ın içinde durur. **Telefona kaydet**, birini telefonunuzun `Recordings/One Dialer` klasörüne kopyalar; diğer uygulamalarınız onu orada görebilir. **Otomatik silme**, yıldızlıları her zaman koruyarak kayıtları 30 veya 90 gün sonra temizleyebilir.",
          },
        ],
      },
      {
        id: "how",
        title: "Nasıl çalışır",
        blocks: [
          {
            p: "Bir aramayı kaydetmenin en temiz yolu doğrudan hattan, iki sesi de tam ses seviyesinde almaktır. Android bunu telefona yerleşik uygulamalara ve **shell**'e ayırır: Android'in kendi hata ayıklama araçlarının komut çalıştırdığı hesap. Kablosuz hata ayıklama, telefondaki bir uygulamanın Shizuku'nun yaptığı gibi bu hesapla bir program başlatmasına izin verir.",
          },
          {
            p: "**İki tarafı da kaydet** bunu yapar. Eşlendikten sonra One Recorder kendi uygulamasından shell olarak küçük bir hizmet başlatır. Hizmet tek bir iş yapar: One Recorder istediği sürece aramayı kaydeder ve sesi, anahtarı yalnızca One Recorder'da olan telefon içindeki özel bir bağlantı üzerinden geri verir. One Recorder güncellendiğinde veya kaldırıldığında durur.",
          },
          { p: "One Dialer, One Recorder'a ne zaman başlayıp duracağını söyler. One Recorder sesi kaydeder, dosyaları saklar ve yalnızca Play imzalı One Dialer'a yanıt verir." },
        ],
      },
      {
        id: "nomic",
        title: "Neden mikrofon yöntemi yok",
        blocks: [
          {
            p: "Önceki sürümler bir erişilebilirlik hizmetiyle mikrofondan da kaydedebiliyordu. Android 10'dan beri arama sırasında mikrofonu kullanan bir uygulama yalnızca sessizlik alır; Android yalnızca bazı erişilebilirlik uygulamaları için, dar durumlarda istisna yapar. Üreticiler bunları bile kapatır: test ettiğimiz telefonda, Android 17'li bir vivo'da, bu yolla yapılan kayıtlar sessizdi; Android tüm arama boyunca mikrofonu susturuyordu.",
          },
          {
            p: "Sessizce hiçbir şey kaydetmeyen bir yöntem hiç olmamasından kötüdür, bu yüzden kaldırıldı; onunla birlikte mikrofon izni, erişilebilirlik hizmeti ve yalnızca onun kullandığı Ses yükseltme ve Mikrofon kaynağı ayarları da gitti. Artık tek yol iki tarafı Kablosuz hata ayıklama üzerinden kaydetmek ve iki sesi de tam ses seviyesinde kaydediyor.",
          },
        ],
      },
      {
        id: "privacy",
        title: "Gizlilik",
        blocks: [
          { p: "Bu çeviri kolaylık içindir; bu sayfanın İngilizce metni esastır." },
          {
            p: "One Recorder yalnızca kaydetmeyi seçtiğiniz bir arama sürerken kayıt yapar. Ses yalnızca telefonunuzdaki One Recorder'ın içine kaydedilir. Asla yüklenmez, hesap yoktur ve siz bir kaydı paylaşmadıkça sizinle ya da aramalarınızla ilgili hiçbir şey telefondan çıkmaz. Kayıtlar, onları sildiğinizde veya One Recorder'ı kaldırdığınızda silinir.",
          },
          {
            p: "Kablosuz hata ayıklama ile eşlemesi, telefonunuzda One Recorder'ın özel depolamasında tutulan bir anahtardır; yedeklenemez ve başka uygulamalar tarafından okunamaz. Hizmet yalnızca One Recorder için arama kaydeder ve başka bir şey çalıştıramaz. One Recorder'ın mikrofon izni ve erişilebilirlik hizmeti yoktur. Kayıt yasaları ülkeye göre değişir ve gereken yerlerde karşı tarafın onayını almak sizin sorumluluğunuzdadır.",
          },
          {
            p: "**Yasal uyarı.** One Recorder olduğu gibi, hiçbir garanti olmadan sunulur. Bir aramanın iki tarafını da kaydedebilir ve arama kaydı yasaları ülkeye ve bölgeye göre değişir: bazı yerlerde aramadaki herkesin onay vermesi gerekir, bazı yerlerde kayda hiç izin verilmez. Sizin ve karşı tarafın bulunduğu yerin yasalarını bilmek ve bunlara uymak, gereken yerlerde karşı tarafı bilgilendirip onayını almak ve kayıtlarınızı nasıl kullandığınız yalnızca sizin sorumluluğunuzdadır. One Recorder ve One Dialer'ı geliştiren Syed Arham Raza, onu nasıl kullandığınızdan ya da onunla yaptığınız herhangi bir kayıttan sorumlu değildir.",
          },
        ],
      },
      {
        id: "legal",
        title: "Yasal uyarı",
        blocks: [
          { p: "Bu çeviri kolaylık içindir; bu sayfanın İngilizce metni esastır." },
          {
            p: "One Recorder olduğu gibi, hiçbir garanti olmadan sunulur. Bir aramanın iki tarafını da kaydedebilir ve arama kaydı yasaları ülkeye ve bölgeye göre değişir: bazı yerlerde aramadaki herkesin onay vermesi gerekir, bazı yerlerde kayda hiç izin verilmez. Sizin ve karşı tarafın bulunduğu yerin yasalarını bilmek ve bunlara uymak, gereken yerlerde karşı tarafı bilgilendirip onayını almak ve kayıtlarınızı nasıl kullandığınız yalnızca sizin sorumluluğunuzdadır. One Recorder ve One Dialer'ı geliştiren Syed Arham Raza, onu nasıl kullandığınızdan ya da onunla yaptığınız herhangi bir kayıttan sorumlu değildir.",
          },
        ],
      },
      {
        id: "trouble",
        title: "Çalışmazsa",
        blocks: [
          {
            ul: [
              "**One Dialer kaydın duraklatıldığını söylüyor ya da hizmet çalışmıyor:** telefon Wi-Fi olmadan yeniden başladı ya da Geliştirici seçenekleri kapatıldı. Wi-Fi'a bağlanın ve hizmeti One Recorder'da başlatın. Çalışana kadar aramalar kaydedilemez.",
              "**Eşleme kodu kabul edilmiyor:** kodu yazarken eşleme penceresini aynı Wi-Fi ağında açık tutun. Yine olmazsa pencereyi kapatın, yeni bir kod için yeniden açın ve bir kez daha deneyin.",
              "**Kayıtta yalnızca bir ses var ya da hiçbir şey yok:** bazı telefonlar Wi-Fi aramasında bir tarafı kaybeder, birkaçı da hattın kaydına hiç izin vermez. Aynı aramayı mobil ağ üzerinden deneyin.",
              "**One Dialer aramaların kaydedilmediğini söylüyor:** otomatik kayıt açık ama One Recorder hazır değil. Açın ve Hazır olmayan satırları, genellikle hizmeti, düzeltin.",
              "**One Dialer kaydedicinin yalnızca Google Play'deki One Dialer ile çalıştığını söylüyor:** One Dialer bir dosyadan yüklendi ya da 1.0.0-beta.9'dan eski. Google Play'den yükleyin veya iki uygulamayı da güncelleyin.",
              "**Arama ekranında Kaydet seçeneği yok:** One Recorder yüklü değil. One Dialer, yüklenene kadar kayıtla ilgili her şeyi gizler.",
            ],
          },
        ],
      },
      {
        id: "update",
        title: "Güncelleyin veya kaldırın",
        blocks: [
          {
            ul: [
              "**Güncellemek için** APK'yı bu sayfadan yeniden indirin ve eskisinin üzerine yükleyin. Kayıtlarınız ve ayarlarınız kalır.",
              "**Kaldırmak için** One Recorder'ı diğer uygulamalar gibi kaldırın. Bu, içindeki tüm kayıtları siler; saklamak istediklerinizi önce telefonunuza kaydedin. One Dialer çalışmaya devam eder ve kayıt seçeneklerini yeniden gizler.",
              "Kayıt yasaları ülkeye göre değişir. Bazıları aramadaki herkesin onayını ister. Gereken yerlerde karşı tarafı bilgilendirmek ve onayını almak sizin sorumluluğunuzdadır.",
            ],
          },
        ],
      },
    ],
  },
};
