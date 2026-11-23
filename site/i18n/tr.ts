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
    guideTitle: "Kılavuz · One Dialer",
    guideDescription: "One Dialer nasıl kullanılır: SIM'ler, Aramalar'dan arama, tuş takımı, kişiler, engelleme, arama ekranı ve efektler; sık karşılaşılan durumlar için ayarlarla birlikte.",
  },
  nav: {
    label: "Site",
    whatsNew: "Yenilikler",
    guide: "Kılavuz",
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
    guide: "Kılavuz",
    recorder: "One Recorder",
    privacy: "Gizlilik politikası (İngilizce)",
    contact: "İletişim",
    language: "Dil",
  },
  guide: {
    back: "One Dialer'a dön",
    title: "Kılavuz",
    h1: "One Dialer,",
    h1b: "adım adım.",
    lead: "Her şeyin nerede olduğu, her ayarın ne yaptığı ve durumunuza uyan ayarlar.",
    toc: "Bu sayfada",
    intro: "Her adımı resimler ve kısa ekran kayıtları gösteriyor. Ayarlar, Aramalar sekmesindeki ⋮ menüsünde.",
    sections: [
      {
        id: "start",
        title: "Başlarken",
        blocks: [
          {
            ol: [
              "One Dialer'ı açın ve **varsayılan telefon uygulamanız** yapmak için **Varsayılan yap**'a dokunun. Aramalar, son aramalar ve cevapsız arama bildirimleri ancak o zaman çalışır.",
              "Android sorduğunda **Kişiler**, **Telefon** ve **Bildirimler** izinlerini verin.",
              "**Ayarlar**'ı açın. Bir sorun varsa en üstte bir **Dikkat gerekiyor** kartı olur, örneğin “Varsayılan telefon uygulamanız değil” ya da kapalı bildirimler; **Düzelt** düğmesi sizi doğrudan oraya götürür.",
            ],
          },
          { shot: "start-default", alt: "One Dialer'ı varsayılan telefon uygulaması yapmak" },
          { shot: "settings-health", alt: "Dikkat gerekiyor kartı ve Düzelt düğmeleriyle Ayarlar" },
        ],
      },
      {
        id: "calls",
        title: "Aramalar ve son aramalar",
        blocks: [
          { p: "**Aramalar** sekmesi son aramalarınızı listeler. Cevapsız aramalar kırmızıdır, tekrarlananlar gruplanır, engellenenler işaretlenir." },
          { p: "Bir aramaya dokunmanın ne yapacağına siz karar verirsiniz: **Ayarlar › Hızlı arama yapma › Son aramaya dokunma**:" },
          {
            ul: [
              "**Ayrıntıları aç**: güvenli seçim. Aramanın sayfası açılır; numara, geçmiş aramalar, notlar ve bir Ara düğmesiyle.",
              "**Ara**: hemen geri arar. Hızlıdır ama yanlışlıkla yapması kolaydır.",
              "**Tuş takımına yaz**: numarayı tuş takımına koyar, aramadan önce kontrol edip değiştirebilirsiniz.",
            ],
          },
          { shot: "recents-tap", alt: "Ara, Ayrıntıları aç ve Tuş takımına yaz seçenekleriyle Son aramaya dokunma ayarı" },
          {
            ul: [
              "**Satırlarda arama düğmesi** her satıra bir arama düğmesi koyar; dokunma ayrıntıları açar, düğme arar. **Ara düğmesi stili** görünüşünü değiştirir.",
              "**Aramak veya mesaj için kaydır**: bir satırı sağa kaydırınca arar, sola kaydırınca mesaj yazar.",
              "**Kişiye göre grupla** bir kişinin aramalarını bir araya toplar.",
              "Birden fazla aramayı seçmek için bir satırı basılı tutun, örneğin silmek için.",
            ],
          },
          { shot: "recents-swipe", alt: "Aramak için son aramayı sağa kaydırmak" },
        ],
      },
      {
        id: "sims",
        title: "İki SIM",
        blocks: [
          { p: "İki SIM ile her aramanın hangisini kullanacağına **Ayarlar › SIM kartlar** karar verir. Ayrı ayrı seçilir:" },
          {
            ul: [
              "**Tuş takımı ve kişiler**: **Telefonun varsayılan SIM'i** ya da aradığınızda SIM seçici gösteren **Her seferinde sor**.",
              "**Son aramaya dokunma** ve **Aramak için kaydır**: **Tuş takımıyla aynı**, **Son kullanılan SIM** (o aramanın SIM'i), **Her seferinde sor** ya da hep aynı SIM. Yalnızca o arama türü Hızlı arama yapma'da açıksa kullanılır.",
            ],
          },
          { shot: "sim-settings", alt: "SIM kartlar ayarları" },
          { p: "Bir kişinin **kendi SIM'i** olabilir: sayfasını açıp seçin. Yukarıdaki her kuraldan önce gelir." },
          { shot: "sim-contact", alt: "Bir kişinin sayfasında SIM seçmek" },
          { p: "Tuş takımında **Ayarlar › Tuş takımı › İki Ara düğmesi** tek düğme yerine her SIM için bir Ara düğmesi gösterir, aradığınız anda seçersiniz." },
          { shot: "sim-chooser", alt: "Her seferinde sor ile ararken SIM seçici" },
        ],
      },
      {
        id: "keypad",
        title: "Tuş takımı",
        blocks: [
          {
            ul: [
              "Rakam ya da harf yazın: eşleşen kişiler siz yazarken çıkar (**T9**). Aramak ya da açmak için birine dokunun.",
              "Sesli mesaj için **1**'i, hızlı arama için **2–9**'u basılı tutun. Hızlı aramayı **Ayarlar › Tuş takımı › Hızlı arama**'dan ayarlayın.",
              "**+** için **0**'ı basılı tutun. Dahili numaralar için duraklama eklemek üzere yıldız tuşunu (*), bekleme için **#**'yi basılı tutun.",
              "Kopyaladığınız bir numarayı yapıştırmak için numaraya basılı tutun. Silmek için **Sil**'i basılı tutun.",
              "Aramalarınızı görmek için tuş takımını aşağı kaydırın ya da tutamacına dokunun. Gezinme çubuğunun yanındaki yeşil düğme onu numaranız korunmuş olarak geri getirir.",
            ],
          },
          { shot: "keypad-t9", alt: "Eşleşen kişilerle tuş takımında yazmak" },
          { shot: "keypad-speed-dial", alt: "Hızlı arama ayarları" },
        ],
      },
      {
        id: "contacts",
        title: "Kişiler",
        blocks: [
          {
            ul: [
              "Favoriler en üstte, ★ altında. Atlamak için sağdaki **A–Z** dizininde parmağınızı kaydırın.",
              "Sayfasını açmak için bir kişiye dokunun: numaralar, kendi SIM'i, arama arka planı ve engelleme. Birden fazlasını seçmek için basılı tutun.",
              "**⋮ › Kişileri yönet** hangi hesapların görüneceğini, sıralamayı ve ad biçimini, yeni kişilerin nereye kaydedileceğini, içe ve dışa aktarmayı, SIM kişilerini ve **Yinelenen kişileri birleştir**'i ayarlar.",
            ],
          },
          { shot: "contacts-index", alt: "Favoriler ve A–Z dizini ile Kişiler" },
          { shot: "contacts-manage", alt: "Kişileri yönet" },
        ],
      },
      {
        id: "blocking",
        title: "Engelleme",
        blocks: [
          {
            ul: [
              "Bir numarayı aramanın ya da kişinin sayfasından engelleyin. **Ayarlar › Engelle ve filtrele › Engellenen numaralar** onları listeler; bu aramaları Android'in kendisi reddeder.",
              "**Bilinmeyen/gizli numaraları engelle** numarasını gizleyenleri durdurur. **Kişilerde olmayan numaralardan gelen aramaları engelle** yalnızca kişilerinizin çaldırmasına izin verir.",
              "Bu iki kural, One Dialer'ın **Arayan kimliği ve spam uygulaması** olmasını gerektirir. Birini açtığınızda One Dialer bunu ister. Bu rolü başka bir uygulama alırsa Ayarlar “Engelleme kuralları duraklatıldı” der.",
              "**Engellenen aramaları gizle** onları Aramalar listesinden çıkarır.",
            ],
          },
          { shot: "blocking-rules", alt: "Engelle ve filtrele ayarları" },
        ],
      },
      {
        id: "callscreen",
        title: "Arama ekranı",
        blocks: [
          {
            ul: [
              "Gelen aramalar, kilit ekranında bile tüm ekranı kaplar. **Ayarlar › Arama ekranı** nasıl yanıtlayacağınızı (yukarı ya da aşağı kaydırma veya düğmeler), efektleri, arayanın fotoğrafını ve arka planı seçer.",
              "Arama sırasında: sessiz, beklet, hoparlör, tuş takımı ve arama ekleme büyük cam düğmelerde. **⋮** daha fazlasını sunar, örneğin One Recorder kuruluysa Kaydet.",
              "**Hızlı ret mesajları**, bir aramayı reddederken gönderebileceğiniz metinlerdir.",
              "**Aramaları yanıtlama ve bitirme** otomatik yanıt, SMS ile yanıt ve hoparlör seçeneklerini içerir. **Kişilerin numaralarını gizle** kayıtlı kişiler için yalnızca adı gösterir.",
            ],
          },
          { shot: "call-incoming", alt: "Kilit ekranında gelen bir arama" },
          { shot: "call-controls", alt: "Arama sırasındaki düğmeler" },
        ],
      },
      {
        id: "look",
        title: "Görünüm ve hız",
        blocks: [
          { p: "**Ayarlar › Ekran ve efektler › Görsel efektleri azalt** uygulamanın ne kadar cam ve bulanıklık çizeceğini belirler. One Dialer ilk seferde telefonunuz için bir düzey seçer; istediğiniz zaman değiştirin:" },
          {
            ul: [
              "**Tüm efektler**: her şey tasarlandığı gibi, cam ve bulanıklık.",
              "**Azaltılmış efektler**: daha düz cam, telefon için çok daha az iş.",
              "**Efektler kapalı**: düz renkler, bulanıklık yok. En hızlısı.",
            ],
          },
          { shot: "effects-levels", alt: "Görsel efektleri azalt: tümü, azaltılmış ve kapalı" },
          { p: "Tüm efektlerle **Cam ve bulanıklık › Cam stili** **Kenar ışıltısı** ya da arkadakini büken ama en çok gücü isteyen deneysel **Sıvı cam** olabilir. **Ekran boyutu** uygulamayı ve gezinme çubuğunu büyütür ya da küçültür; arama ekranının da kendi **Arama ekranı efektleri** vardır." },
          { shot: "glass-style", alt: "Cam stili: Kenar ışıltısı ve Sıvı cam" },
        ],
      },
      {
        id: "more",
        title: "Dil, yedekleme ve güncellemeler",
        blocks: [
          {
            ul: [
              "**Ayarlar › Dil › Uygulama dili** yalnızca One Dialer'ın dilini değiştirir. **Telefonla aynı** Android'i izler.",
              "**Yedekle ve geri yükle** ayarlarınızı, hızlı aramayı, arama notlarını ve arama arka planlarını yeni bir telefon ya da yeniden kurulum için bir dosyaya kaydeder.",
              "**Yazılım güncellemesi** Google Play'de yeni bir sürüm olduğunda yenilikleriyle birlikte gösterir.",
            ],
          },
          { shot: "settings-language", alt: "Uygulama dili ayarları" },
        ],
      },
      {
        id: "setups",
        title: "Sık karşılaşılan durumlar için ayarlar",
        blocks: [
          { p: "Size uyan durumu seçin ve bu ayarları değiştirin." },
          {
            setup: "İnsanları yanlışlıkla arıyorum",
            when: "Son aramaya bir dokunuş ya da kaydırırken bir hareket istemediğiniz bir aramayı başlatıyor.",
            steps: [
              "**Ayarlar › Hızlı arama yapma › Son aramaya dokunma** → **Ayrıntıları aç**.",
              "**Aramak veya mesaj için kaydır**'ı kapatın.",
              "İsteğe bağlı: **Satırlarda arama düğmesi**'ni açın; böylece aramak, düğmeye bilinçli bir dokunuş olur.",
            ],
          },
          { shot: "setup-no-accidents", alt: "Yanlışlıkla aramaları önlemek için ayarlanmış Hızlı arama yapma" },
          {
            setup: "İş SIM'i ve kişisel SIM",
            when: "İş kişilerini bir SIM'den, diğer herkesi öbüründen, her seferinde seçmeden aramak istiyorsunuz.",
            steps: [
              "**Ayarlar › SIM kartlar › Tuş takımı ve kişiler** → kişisel SIM'iniz (ya da Telefonun varsayılan SIM'i).",
              "Her iş kişisinin sayfasında **iş SIM'ini** seçin. Her zaman o kazanır.",
              "**Son aramaya dokunma** → **Son kullanılan SIM**; geri ararken arama hangi SIM'e geldiyse o kullanılır.",
            ],
          },
          { shot: "setup-two-sims", alt: "İş ve kişisel kullanım için SIM ayarları" },
          {
            setup: "Hangi SIM'in kullanılacağından hiç emin değilim",
            when: "İki SIM var ve her aramada siz karar vermek istiyorsunuz.",
            steps: [
              "**Ayarlar › SIM kartlar › Tuş takımı ve kişiler** → **Her seferinde sor**.",
              "**Ayarlar › Tuş takımı › İki Ara düğmesi**'ni açın; tuş takımı her SIM için bir düğme gösterir.",
            ],
          },
          {
            setup: "Telefonum yavaş geliyor",
            when: "Kaydırma takılıyor ya da arama ekranı yavaş açılıyor.",
            steps: [
              "**Ayarlar › Ekran ve efektler › Görsel efektleri azalt** → **Azaltılmış efektler**, eski bir telefonda **Efektler kapalı**.",
              "**Cam stili** → **Kenar ışıltısı** (Sıvı cam değil).",
              "**Arama ekranı efektleri**'ni de düşürün.",
            ],
          },
          { shot: "setup-slow-phone", alt: "Görsel efektleri azalt: Azaltılmış efektler" },
          {
            setup: "Yalnızca tanıdıklarım arasın",
            when: "Spam, gizli ya da bilinmeyen numaralar.",
            steps: [
              "**Ayarlar › Engelle ve filtrele** → **Bilinmeyen/gizli numaraları engelle**'yi ve isterseniz **Kişilerde olmayan numaralardan gelen aramaları engelle**'yi açın.",
              "İstendiğinde One Dialer'ı **Arayan kimliği ve spam uygulaması** olarak kabul edin.",
              "Aramalar düzenli kalsın diye **Engellenen aramaları gizle**'yi açın.",
            ],
          },
          {
            setup: "Aramaları kaydetmek istiyorum",
            when: "Google Play'deki One Dialer hiçbir zaman kendisi kayıt yapmaz. Kayıt ayrı bir uygulamadan, One Recorder'dan gelir.",
            steps: [
              "Bu sitedeki **One Recorder** kılavuzunu izleyin: bir kerelik, yaklaşık beş dakika sürer.",
            ],
          },
        ],
      },
    ],
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
      "Birkaç saatte bir hâlâ çalıştığını denetler ve durmuşsa kendiliğinden yeniden başlar.",
      "Başladıktan sonra Geliştirici seçeneklerini kendisi kapatır, böylece çoğu bankacılık uygulaması açılır.",
      "Şimdi denetle kaydın gerçekten çalıştığını sınar ve son aramanın sonucu kaydedilip kaydedilmediğini gösterir.",
    ],
    consTitle: "Neler beklenir",
    cons: [
      "İki tarafı kaydetmek için Geliştirici seçenekleri ve Kablosuz hata ayıklama bir kez açılmalı, her başlatmada da Wi-Fi gerekir. Yeniden başlatmadan sonra başlayamazsa (Wi-Fi yoksa ya da Geliştirici seçenekleri kapalıysa), One Recorder'da dokunarak başlatırsınız.",
      "Bazı telefonlarda kaydın çalışmaya devam etmesi için USB ya da kablosuz hata ayıklamanın açık kalması gerekir ve bazı bankacılık uygulamaları o zaman da açılmaz.",
      "Bazı telefonlarda Wi-Fi araması üzerinden yapılan aramalarda yalnızca bir taraf kaydedilir. Bu, One Recorder'dan değil telefonun ses sürücüsünden kaynaklanır.",
      "Android 12 veya üstü gerekir. Android 10 ve 11, hizmeti Kablosuz hata ayıklama üzerinden başlatamaz ve orada kaydetmenin başka yolu yoktur.",
      "Google Play'de değil. Yeni sürümleri kendisi GitHub'da arar ve Yazılım güncellemesi'nden yükler.",
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
        title: "İki tarafı da kaydet",
        blocks: [
          { p: "One Recorder'ı açın: adımlar **Kurulum** altında ve ilerledikçe her birine yeşil bir onay işareti gelir. Üstteki **Devam** her zaman sıradaki adımı yapar." },
          { shot: "rec-setup", alt: "One Recorder'ın kurulum adımları" },
          {
            ol: [
              "**Bildirimler.** Önce bunlara izin verin: eşleme kodu One Recorder'ın bildirimine yazılır.",
              "**Geliştirici seçenekleri.** Kapalıysa **Ayarlar › Telefon hakkında**'yı açın (bazı telefonlarda Telefon hakkında › Yazılım bilgileri) ve **Yapım numarası**'na yedi kez dokunun.",
              "**Kablosuz hata ayıklama ile eşle.** Satıra dokunun. One Recorder Geliştirici seçeneklerini açar ve bir bildirim gösterir. **Kablosuz hata ayıklama**'yı açın, içine girin ve **Cihazı eşleme koduyla eşle**'ye dokunun.",
              "Kodu ekranda bırakın, One Recorder'ın bildirimini aşağı çekin, **Kodu girin**'e dokunun ve altı haneyi yazın. One Recorder eşlenir ve hizmetini başlatır. Yalnızca bir kez eşlersiniz.",
              "**Ya da otomatik eşleyin:** One Recorder'da **Otomatik eşle (isteğe bağlı)**'yı açın. Kodu eşleme penceresinden kendisi okur, sonra kendini kapatır. Android 13 ve sonrasında gri görünüyorsa önce One Recorder'ın Uygulama bilgisi › ⋮ › **Kısıtlanmış ayarlara izin ver**'i açın.",
              "**Kayıt hizmetini başlat.** Çalışmıyorsa Wi-Fi'de olduğunuzdan emin olun ve satıra dokunun. **Yeniden başlatmadan sonra başlat** ilk başlatmada kendiliğinden açılır.",
            ],
          },
          { shot: "rec-pair", alt: "Eşleme kodunu One Recorder'ın bildirimine yazmak" },
          { p: "**Pil: Kısıtlanmamış** son adımdır. Bir arama beklerken telefonun kaydediciyi kapatmasını önler." },
        ],
      },
      {
        id: "devoptions",
        title: "Geliştirici seçenekleri ve bankacılık uygulamaları",
        blocks: [
          { p: "Birçok bankacılık ve ödeme uygulaması Geliştirici seçenekleri, USB hata ayıklama ya da kablosuz hata ayıklama açıkken açılmaz. **Geliştirici seçeneklerini kapat** varsayılan olarak açıktır: kayıt hizmeti başladıktan sonra One Recorder bunları tek tek kapatır ve her birinden sonra kaydın hâlâ çalıştığını denetler." },
          { p: "Bazı telefonlar USB ya da kablosuz hata ayıklama kapanınca kayıt hizmetini durdurur. One Recorder o zaman onu yeniden açar ve açık bırakır, satır da bunu söyler. Hizmeti yeniden başlatması gerektiğinde (yeniden başlatmadan sonra ya da Wi-Fi'ye dönünce) onları kısa süre açıp yeniden kapatır." },
          { shot: "rec-devoptions", alt: "Geliştirici seçeneklerini kapat ayarı" },
        ],
      },
      {
        id: "check",
        title: "Çalıştığını denetleyin",
        blocks: [
          {
            ul: [
              "**Şimdi denetle** (Kurulum altında) kayıt hizmeti durmuşsa onu başlatır, bu da One Recorder'ın hâlâ eşli olduğunu kanıtlar; sonra kısa bir süre arama sesini açtırır. Saati ve sonucu gösterir.",
              "Kablosuz hata ayıklama One Recorder'ı artık kabul etmiyorsa Şimdi denetle, Eşlendi demeye devam etmek yerine sizi eşleme adımına geri götürür.",
              "Kaydettiğiniz her aramadan sonra One Recorder'ın üstünde sonuç görünür: ne zaman ve ne kadar sürdüğü, ya da kayıt sessizse veya arama kaydedilmediyse kırmızı.",
            ],
          },
          { shot: "rec-check", alt: "Şimdi denetle ve son aramanın sonucu" },
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
          { shot: "rec-recordings", alt: "One Dialer'daki kayıtlar" },
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
        id: "setups",
        title: "Sık karşılaşılan durumlar için ayarlar",
        blocks: [
          {
            setup: "Bankacılık uygulamaları kullanıyorum",
            when: "Kayıt ve bankacılık uygulamanız aynı telefonda olsun istiyorsunuz.",
            steps: [
              "**Geliştirici seçeneklerini kapat**'ı açık bırakın (varsayılan).",
              "**Wi-Fi olmadan kaydetmeye devam et**'i kapalı bırakın: USB hata ayıklamayı açık tutar.",
              "Satır telefonunuzun bir hata ayıklamanın açık kalmasını istediğini söylüyorsa bankacılık uygulamasını yine de deneyin: çoğu yalnızca Geliştirici seçeneklerine bakar.",
            ],
          },
          {
            setup: "Wi-Fi yokken de kaydetmek istiyorum",
            when: "Wi-Fi gidince kayıt hizmeti durur, çünkü kablosuz hata ayıklama Wi-Fi ister.",
            steps: [
              "**Wi-Fi olmadan kaydetmeye devam et**'i açın. USB hata ayıklamayı açık tutar, böylece hizmet mobil veride de çalışır.",
              "Açıkken bazı bankacılık uygulamaları açılmaz.",
            ],
          },
          { shot: "rec-away-wifi", alt: "Wi-Fi olmadan kaydetmeye devam et" },
          {
            setup: "Telefonum sık sık Wi-Fi yokken yeniden başlıyor",
            when: "Yeniden başlatmadan sonra hizmet başlamak için Wi-Fi'yi bekler.",
            steps: [
              "**Yeniden başlatmadan sonra başlat**'ın kendiliğinden başladığını söylediğinden emin olun.",
              "Android 12–16'da **Wi-Fi olmadan başlat (deneysel)**'i deneyin. Konumun açık olması gerekir ve her telefonda çalışmayabilir.",
            ],
          },
          {
            setup: "Kayıtlarım sessiz ya da kısık",
            when: "Bir kayıtta ses yok ya da karşı taraf zor duyuluyor.",
            steps: [
              "**Şimdi denetle**'ye dokunun. Her şey çalışmıyorsa gösterdiği adımı düzeltin.",
              "Aynı aramayı Wi-Fi araması yerine mobil ağ üzerinden deneyin.",
              "Hâlâ sorunluysa: **Tanılamayı paylaş** ve bir hata bildirimiyle gönderin.",
            ],
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
              "**Bir bankacılık uygulaması hâlâ açılmıyor:** telefonunuz USB ya da kablosuz hata ayıklamanın açık kalmasını istiyor (One Recorder'daki Geliştirici seçeneklerini kapat satırı hangisi olduğunu söyler). **Wi-Fi olmadan kaydetmeye devam et** açıksa kapatın, çünkü USB hata ayıklamayı açık tutar.",
              "**Hâlâ çözülmedi:** One Recorder'da **Tanılamayı paylaş**'a dokunun ve raporu hata bildiriminizle gönderin. Sürümleri, telefon modelini, kurulum durumunu ve son günlük satırlarını içerir; numara ya da ad içermez.",
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
              "**Güncellemek için** One Recorder › **Yazılım güncellemesi**'ni açın. Kayıt hizmeti çalışırken yeni sürümü kendisi, sormadan yükler; aksi hâlde siz yükleyesiniz diye indirir. APK'yı bu sayfadan indirip eskisinin üzerine de yükleyebilirsiniz. Kayıtlarınız ve ayarlarınız kalır.",
              "**Kaldırmak için** One Recorder'ı diğer uygulamalar gibi kaldırın. Bu, içindeki tüm kayıtları siler; saklamak istediklerinizi önce telefonunuza kaydedin. One Dialer çalışmaya devam eder ve kayıt seçeneklerini yeniden gizler.",
              "Kayıt yasaları ülkeye göre değişir. Bazıları aramadaki herkesin onayını ister. Gereken yerlerde karşı tarafı bilgilendirmek ve onayını almak sizin sorumluluğunuzdadır.",
            ],
          },
        ],
      },
    ],
  },
};
