# Translate One Dialer into your language

You don't need to know how to code. You fill in two text files, and the maintainer puts them in the app.

It takes a few evenings: the app has about 540 short pieces of text. You can send a half-finished file too. Anything you leave in English shows in English until someone finishes it.

## Step 1: Download the two files

1. [**app_xx.arb**](https://github.com/syedarhamraza/one-dialer/raw/HEAD/translations/app_xx.arb) has almost all the app's text.
2. [**strings_xx.xml**](https://github.com/syedarhamraza/one-dialer/raw/HEAD/translations/strings_xx.xml) has the text of the call notifications (Answer, Decline, Missed call...).

If a link opens the text in your browser instead of downloading it, right-click it and choose **Save link as...**

## Step 2: Open them in a text editor

Any plain text editor works: **Notepad** on Windows, **TextEdit** on Mac (Format › Make Plain Text), or a free editor like [Notepad++](https://notepad-plus-plus.org/) or [VS Code](https://code.visualstudio.com/), which colour the text and make mistakes easier to spot.

Don't use Word or Google Docs: they change quotes and break the file.

## Step 3: Replace the English with your language

### In app_xx.arb

Every line looks like this:

```
"cancel": "Cancel",
```

The left side (`"cancel"`) is the name the app uses to find the text. **Never change it.**
The right side (`"Cancel"`) is what people see. **Replace only that**, inside the quotes:

```
"cancel": "Cancelar",
```

Change the first two lines too:

```
"@@locale": "es",
"languageName": "Español",
```

- `@@locale` is your language's code (see the table at the end).
- `languageName` is your language's name, written in your language, as it will appear in Settings › Language.

**Words in curly brackets are filled in by the app.** Keep them exactly as they are, but move them wherever your grammar needs them:

```
"speedDialRemoved": "Removed {name} from {digit}",
"speedDialRemoved": "Se quitó a {name} de la tecla {digit}",
```

**Some texts change with a number.** Translate only the parts inside `{...}` after `=1`, `one` or `other`, and keep the rest:

```
"deleteCallsTitle": "{count, plural, =1{Delete call?} other{Delete {count} calls?}}",
"deleteCallsTitle": "{count, plural, =1{¿Eliminar la llamada?} other{¿Eliminar {count} llamadas?}}",
```

**Some texts pick from a list** (`select`). Translate only the text inside each `{...}`, never the word in front of it:

```
"... mobile{Mobile} home{Home} work{Work} ..."
"... mobile{Móvil} home{Casa} work{Trabajo} ..."
```

### In strings_xx.xml

Lines look like this. Replace only the text between `>` and `</`:

```
<string name="decline">Decline</string>
<string name="decline">Rechazar</string>
```

- Keep `%1$s` and `%d`: the app puts a name or a number there.
- An apostrophe needs a backslash in front of it: `I\'ll call you back`.
- For texts with `<item quantity="one">` and `<item quantity="other">`, translate both. If your language counts differently (for example `few` or `many`), say so when you send the file, and we'll add the right lines together.

### Keep these as they are

- **One Dialer**, **WhatsApp**, **Google Play** and other brand names
- Anything inside `{curly brackets}` that is a single word with no spaces (`{name}`, `{count}`, `{digit}`)
- Quotes `"`, commas `,` and brackets at the ends of the lines

## Step 4: Send it

Pick whichever is easier for you.

**Option A: open an issue (easiest).**

1. [Create a free GitHub account](https://github.com/signup) if you don't have one.
2. Open a [**new translation issue**](https://github.com/syedarhamraza/one-dialer/issues/new?template=translation.yml).
3. Fill in the language, and drag both files into the box. GitHub may refuse `.arb` and `.xml` files. If it does, put them in a `.zip` first, or add `.txt` to the end of their names.

**Option B: open a pull request on GitHub's website** (if you've used GitHub before).

1. Open [lib/l10n](https://github.com/syedarhamraza/one-dialer/tree/HEAD/lib/l10n) and choose **Add file › Upload files**. Upload your ARB file renamed to `app_<code>.arb` (for example `app_es.arb`).
2. Upload your XML file to `android/app/src/main/res/values-<code>/strings.xml`. To make the new folder, choose **Add file › Create new file** in `android/app/src/main/res` and type `values-es/strings.xml` as its name, then paste the contents.
3. GitHub offers to create a pull request. Do it.

## Step 5: What happens next

The maintainer checks the files and runs the tests, which catch a missing `{name}` or a broken line. They add your language to the app's list and send you a test version to look at on your phone. Some text can look different in the app than in the file (too long for a button, for example), so this is the moment to fix it.

If you like, you'll be credited by the name you gave.

**Keeping it up to date:** new versions of the app sometimes add text. Download `app_xx.arb` again and compare it with yours, or ask in your language's issue which lines are new.

## Language codes

| Language | Code | | Language | Code |
|---|---|---|---|---|
| Arabic | `ar` | | Indonesian | `id` |
| Bengali | `bn` | | Japanese | `ja` |
| Chinese (Simplified) | `zh` | | Korean | `ko` |
| Dutch | `nl` | | Persian | `fa` |
| French | `fr` | | Polish | `pl` |
| German | `de` | | Portuguese | `pt` |
| Hindi | `hi` | | Russian | `ru` |
| Spanish | `es` | | Turkish | `tr` |
| Urdu | `ur` | | Vietnamese | `vi` |

Not listed? Use the two-letter [ISO 639-1 code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) for your language.

Languages written right to left (Arabic, Urdu, Persian, Hebrew) are very welcome. They also need some layout work in the app, which the maintainer will do once the translation arrives.

---

Developers: how languages are wired into the app is in [docs/localization.md](docs/localization.md). After changing English text, run `dart run tool/l10n_template.dart` to refresh the templates; `flutter test` fails until you do.
