+++
title = "Encrypting Files With Node"
date = "2018-04-18"
+++

_I received good feedback from some kind Reddit users who pointed out that there are a few implementation errors. You can read the thread [here](https://old.reddit.com/r/javascript/comments/8doo5t/lets_encrypt_files_with_node/). If you're coming from little to no knowledge on encryption, there is still a lot you can learn in this article, but don't use the code you find here in a production system. Without further ado…_

---

We're going to build a CLI program which will allow us to compress and encrypt a file using a password, and then decrypt and uncompress that file using that same password. We'll be doing it entirely in Node with no external dependencies.

Overall, the plan is to:

1. Read some plaintext.
2. Compress it.
3. Encrypt it.
4. Append data used in the encryption process (which is needed for decryption later).
5. Write the cipher text to a file.

Then, we'll need to reverse those steps:

1. Read some cipher text.
2. Pull the encryption data.
3. Decrypt it.
4. Decompress it.
5. Write the plaintext to a file.

What we'll be learning

- How to work with Node streams.
- How to write custom streams.
- How to use some of the crypto functions.
- A little bit about AES encryption.

Sound good? Let's get started.

_**If you just want to see the source code, it's on Github [here](https://github.com/bbstilson/node-encryption).**_

## Part 0: Preparing our project

First, let's create a directory, and, in it, create two files, `index.js` and `file.txt`. Our directory should look like this:

```plaintext
├── index.js
└── file.txt
```

In `file.txt`, let's put a little bit of text (I used a paragraph from [baconipsum](https://baconipsum.com/)):

>Spicy jalapeno bacon ipsum dolor amet fugiat fatback ut flank dolor in ea, aute buffalo duis. T-bone occaecat sunt nisi commodo pig. Beef ullamco prosciutto irure cow dolore. Reprehenderit chicken ut, pork chop venison consectetur quis in. Ut pig duis aliqua.

## Part 1: Node Streams - A Quick Primer

### Reading Files

In Node, your application code runs in a single thread. The stdlib provides access to APIs that run I/O processes in separate, system managed threads and invoke your application level callbacks as appropriate.

For example, if you want to read a file, you can do it synchronously like this:

```js
const fs = require('fs');
const fileContents = fs.readFileSync('./file.txt');
console.log(fileContents);
```

That totally works, but it's blocking and is loading everything into memory, which is not ideal. Imagine if file.txt was several gigabytes! Streams, on the other hand, are a powerful tool that allows us to write programs which deal with small amounts of data in an asynchronous manner. This keeps our programs much more memory efficient and available to process other requests.

Let's rewrite this using a read stream:

```js
const fs = require('fs');
const readStream = fs.createReadStream('./file.txt');
readStream.on('data', (chunk) =>{
  console.log(chunk.toString('utf8'));
});
```

What this is doing is pretty cool. `createReadStream` is asynchronously reading a file bit by bit without blocking the rest of the code execution. Currently, though, it's a bit clunky, and we can use a cool feature of streams: piping.

```js
const fs = require('fs');
const readStream = fs.createReadStream('./file.txt');
readStream.pipe(process.stdout);
```

This accomplishes the exact same thing as the above code in fewer lines. In Node (unless you change it), `console.log` writes to `process.stdout`, and because `process.stdout` is a stream, we can tell it to print out each chunk of data as it receives it from the read stream.

### Writing Files

Let's expand this code to create a new file. For that, we need a new method: `createWriteStream`.

```js
const fs = require('fs');
const readStream = fs.createReadStream('./file.txt');
const writeStream = fs.createWriteStream('./newfile.txt');
readStream.on('data', (chunk) => {
  writeStream.write(chunk);
});
```

Here, we're calling the `write` method on the write stream with the chunk of data we read from the read stream. But again, this is kind of clunky. Rather than invoking `write`, let's do what we did before and pipe the read stream directly to the write stream!

```js
const fs = require('fs');
const readStream = fs.createReadStream('./file.txt');
const writeStream = fs.createWriteStream('./newfile.txt');
readStream.pipe(writeStream);
```

Much better.

Piping, besides being more terse, handles both writing to the stream as well as closing, or `end`ing, the stream, which triggers an "on finished" event that can be listened to and acted in response to.

So, now we have a pretty useless program which creates a new file with the exact same data as some other file, but we're headed in the right direction.

### Compression

Rather than simply writing the same contents to a new file, let's compress that file as we write it. For that, we'll need another Node module: [`zlib`](https://nodejs.org/api/zlib.html). `zlib` has a couple compression and decompression schemes, but the one we're going to use is gzip, which is a standard compression algorithm that compresses content really well.

To create a gzip stream in Node, we need to require the `zlib` module, then create a gzip stream:

```js
const fs = require('fs');
const zlib = require('zlib');
const readStream = fs.createReadStream('./file.txt');
const gzipStream = zlib.createGzip();
const writeStream = fs.createWriteStream('./newfile.txt');
readStream
  .pipe(gzipStream)
  .pipe(writeStream);
```

That's it! We've written a program that is basically saying, "Read a chunk of data, pass that chunk to the gzip stream to be compressed, then write that compressed chunk to a new file. Do that until there are no more chunks to read from the original file."

Let's checkout `newfile.txt`:

```plaintext
1f8b 0800 0000 0000 0013 b590 d151 0331
0c44 ffa9 620b 0857 0425 1028 40a7 d325
e26c cbb1 2518 ba47 09b4 c097 343b 3bda
b73a 77e5 6f7c 50a1 2ecd b012 5b83 f619
159b 151b a02a 8e3d 2e4a 39c8 d370 2072
2dd4 8e3f 8b36 089d 40e1 8235 f69d 8a61
0b9d 0bde 9e57 6b02 6326 e13c 30a3 399a
4e05 5bad b619 ba5e 16bc 88ec 8852 a872
2ac3 266b b81b 74c4 90b4 7efd 06c9 8257
e943 aed2 3619 eae0 abf2 212d 794e e836
8e14 ace3 5332 215b 6493 29ec e231 704b
9ce4 5cf0 eef7 c807 1ea8 e82d 68c1 f93f
7ff0 f403 304e c86c 6201 0000
```

Cool, binary data. Not super readable, but it is much smaller (~42% smaller)!

```plaintext
> ls -lh
354B file.txt
204B newfile.txt
```

The next step is to encrypt this bad boy.

## Part 2: Encryption

The encryption algorithm we're going to be using is AES - specifically AES-256. [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) is a symmetric-key algorithm, meaning the same key is used for both encrypting and decrypting the data. It is one of the most popular and widely used encryption algorithms. There are three variants (block sizes) of AES: 128, 192, and 256. We'll be using the 256 variant of AES as it is the most secure. This is a great comic about AES if you want to know more: [A Stick Figure Guide to the Advanced Encryption Standard](http://www.moserware.com/2009/09/stick-figure-guide-to-advanced.html).

Node has a built-in [crypto](https://nodejs.org/api/crypto.html) module, which provides several cryptographic tools which largely run OpenSSL functions under-the-hood. There are tons of really cool things in this module, but for our purposes, we're going to be creating a cipher.

There are two functions for creating ciphers: `createCipher` and `createCipheriv`. Before we understand which one we should choose, let's quickly learn about initialization vectors. An initialization vector, is a cryptographically secure pseudo-random number which ensure that, given the same plaintext and password (or key), the same cipher text is not produced [1].

`createCipher` is less secure than `createCipheriv` as it auto-generates an initialization vector based on the password that was used to create the cipher, and, due to the internal mechanics of how that initialization vector is generated, it is vulnerable to certain types of attack. (You can read more details on the `createCipher` [docs](https://nodejs.org/api/crypto.html#crypto_crypto_createcipher_algorithm_password_options)). Given that, we're going to use `createCipheriv`.

Looking at the documentation for `createCipheriv`, we need to provide three things:

1. The algorithm. (We chose this already: AES-256).
2. A cipher key.
3. An initialization vector.

How do we choose a key and initialization vector?

### Generating a cipher key

The key needs to be the size of the block (in bits). So, given that we're using AES-256, we need a 256 bit, or 32 byte, key. We can do this in a few ways. The easiest one would be to ask the crypto module to give you 32 random bytes:

```js
const KEY = crypto.randomBytes(32);
KEY // <Buffer 60 6f 9b 16 52 72 6c 32 54 67 17 18 1b db e7 0b ee 64 80 ee d8 f4 98 f8 d2 58 b8 23 82 06 cd 15>
KEY.length // 32
```

This would allow us to create a cipher for AES-256, but this key is effectively going to be our password for a file, so randomly generating one isn't very useful as no one will be able to remember it. What we could do instead is create a hash of the password using another crypto method: `createHash`.

```js
const hash = crypto.createHash('sha256');
hash.update('mySup3rC00lP4ssWord');
const KEY = hash.digest();
KEY // <Buffer ee b6 af 01 b3 1f 1f 01 a6 2f 14 92 2c 5c 80 54 ad 6d 51 cb 99 8c 28 f0 56 a7 ec 08 61 a6 aa ef>
KEY.length // 32
```

A cryptographically secure hash function has three factors which are useful for generating a key for our cipher:

1. It is one-way, meaning it's very difficult, given a hash, to reverse it and figure out what went in.
2. It produces a fixed output length. For sha256, it will always produce a 32 byte buffer, which just happens to be the size we needed for our AES-256 cipher.
3. It's deterministic. That is, the hash function will always produce the same hash for the same plaintext.

Let's wrap that functionality in a helper function:

```js
function getCipherKey(password) {
  return crypto.createHash('sha256').update(password).digest();
}
```

This will allow us to easily get a cipher key for any password.

You might be asking yourself, "If the same hash is generated for a password, isn't out encryption weak?". That's where the initialization vector comes in.

### Generating an initialization vector

The rules for an initialization vector are a bit different. The most important aspect of an initialization vector is that it is never reused. We can ensure this will be the case by generating a random initialization vector for each file we encrypt. We already saw how to do this above when we generated a key:

```js
const initVect = crypto.randomBytes(16);
```

So long as the initialization vector is generated using a cryptographically secure random (or pseudo-random) number generator, getting the same initialization vector is extremely unlikely.
As was mentioned, AES is a symmetric-key algorithm. This means that we need to know about all the input into our cipher in order to decrypt the ciphertext. The user keeps track of their password, and we're using a deterministic hash function to generate our key.

But what about the initialization vector? That was randomly generated, so no one knows it. As it turns out, the initialization vector does not need to be kept secret; the key protects the encrypted data, whereas the use of a random initialization vector ensures that information is not leaked by the cipher text itself. As such, it should not be encrypted with the plaintext and can simply be sent "in the clear". Typically, this is done by appending the initialization vector to the front of the cipher text.

If we were dealing with some strings, we could just do something like:

```js
function encrypt(text, password) {
  const initVect = crypto.randomBytes(16);
  const key = getCipherKey(password);

  const cipher = createCipheriv('aes256', key, initVect);
  const cipherText = cipher.update(text).digest();

  return initVect + ciphertext;
}

encrypt('hello', 'mygr8password');
```

That's basically what we want, but this won't work if we want to encrypt something large like a movie or very large text document.

We do, however, have a means of dealing with very large files: streams! But how do we append something to a stream?

### Keeping track of the cipher input

Easy: we create our own appender stream. Node makes this simple by providing access to all the underlying streams. In brief ([from the documentation](https://nodejs.org/api/stream.html)):

>There are four stream types within Node.js:
>
>- `Readable` - streams from which data can be read (for example `fs.createReadStream()`).
>
>- `Writable` - streams to which data can be written (for example `fs.createWriteStream()`).
>
>- `Duplex` - streams that are both `Readable` and `Writable` (for example `net.Socket`).
>
>- `Transform` - `Duplex` streams that can modify or transform the data as it is written and read (for example `zlib.createDeflate()`).

Since we will be modifying the data, we will need to use a Transform stream.

```js
const { Transform } = require('stream');

class AppendInitVect extends Transform {
  constructor(initVect, opts) {
    super(opts);
    this.initVect = initVect;
    this.appended = false;
  }

  _transform(chunk, encoding, cb) {
    if (!this.appended) {
      this.push(this.initVect);
      this.appended = true;
    }
    this.push(chunk);
    cb();
  }
}

module.exports = AppendInitVect;
```

This class takes the initialization vector as a constructor argument, and pushes it to the stream before the first chunk of data is pushed. Then, after pushing the `initVect`, we flip a flag and let the rest of the data stream through unmodified.

### Assembling an encryption function

Let's pipe all these together and wrap it in a function:

```js
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const AppendInitVect = require('./appendInitVect');
const getCipherKey = require('./getCipherKey');

function encrypt({ file, password }) {
  // Generate a secure, pseudo random initialization vector.
  const initVect = crypto.randomBytes(16);
  
  // Generate a cipher key from the password.
  const CIPHER_KEY = getCipherKey(password);
  const readStream = fs.createReadStream(file);
  const gzip = zlib.createGzip();
  const cipher = crypto.createCipheriv('aes256', CIPHER_KEY, initVect);
  const appendInitVect = new AppendInitVect(initVect);
  // Create a write stream with a different file extension.
  const writeStream = fs.createWriteStream(path.join(file + ".enc"));
  
  readStream
    .pipe(gzip)
    .pipe(cipher)
    .pipe(appendInitVect)
    .pipe(writeStream);
}
```

We can run this function by passing it a path to the file you want to encrypt and a password:

```js
encrypt({ file: './file.txt', password: 'dogzrgr8' });
```

## Part 3: Decryption

To decrypt a file, we need to do everything we did to encrypt it but in reverse. We'll need to:

1. Read the file.
2. Get the initialization vector.
3. Decrypt the cipher text
4. Uncompress it.
5. Write the plaintext to a file.

### Reading the cipher text

We've seen how easy it is to read data from a file using a write stream. However, there's a slight twist to what we need to do here. Our cipher text file isn't just the encrypted plaintext; it also has the initialization vector prepended to the file. We need to separate the IV from the rest of the cipher text. Given that a stream deals with chunks of a file, how can we know the first chunk of data contains our initialization vector and only our initialization vector? Similarly, how do we know that the second chunk is the start of our cipher text?

According to the `readStream` [docs](https://nodejs.org/api/fs.html#fs_fs_createreadstream_path_options), `createReadStream` takes two arguments: path and options. Via the options argument, we can tell the stream where to `start` and `end`. So, rather than using one stream, we can use two streams: one for the `initVect` and the other for the cipher text.

```js
// First, create a stream which will read the init vect from the file.
const readIv = fs.createReadStream(filePath, { end: 15 });
// Then, wait to get the initVect.
let initVect;
readIv.on('data', (chunk) => {
  initVect = chunk;
});
// Once we've got the initialization vector, we can decrypt
// the file.
readIv.on('close', () => {
  // start decrypting the cipher text…
});
```

Since we know that the initialization vector for AES-256 is 16 bytes, we can tell the stream to only read the first 16 bytes. Once we've captured the initialization vector, and the read stream has closed, we can start decrypting the cipher text.

Similar to what we did to only read the initialization vector, we need to create a stream which will start reading after the initialization vector:

```js
// inside the 'close' callback for the read initVect stream.
const readStream = fs.createReadStream(filePath, { start: 16 });
```

Now that we have access to the initialization vector, the password, and the cipher text, we're ready to start decrypting our file.

### Deciphering

Similar to how we encrypted the file using `createCipheriv`, we're going to use a new method: `createDecipheriv`. It takes the same arguments as `createCipheriv`:

```js
const cipherKey = getCipherKey(password);
const decipher = crypto.createDecipheriv('aes256', cipherKey, initVect);
```

Let's pipe this onto our read stream:

```plaintext
readStream
  .pipe(decipher);
```

### Decompression

Next step is decompressing the file. In the same way that we created a gzip stream using the `createGzip` method, we'll be using its inverse: `createUnzip`.

```js
const unzip = zlib.createUnzip();
```

Let's also add that to our pipe stream:

```js
readStream
  .pipe(decipher)
  .pipe(unzip);
```

### Writing again

Last but not least, let's create a new write stream so we can write our decrypted, decompressed file.

```js
// Add an extension so it doesn't overwrite any files and
// so we can identify it.
const writeStream = fs.createWriteStream(filePath + '.unenc');
// Let's add that to our pipe stream.
readStream
  .pipe(decipher)
  .pipe(unzip)
  .pipe(writeStream);
```

### Assembiling a decryption function

Let's put everything together, wrap it in a function, and put it in a file:

```plaintext
touch decrypt.js
```

Inside `decrypt.js`:

```js
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const getCipherKey = require('./getCipherKey');

function decrypt({ file, password }) {
  // First, get the initialization vector from the file.
  const readInitVect = fs.createReadStream(file, { end: 15 });

  let initVect;
  readInitVect.on('data', (chunk) => {
    initVect = chunk;
  });

  // Once we’ve got the initialization vector, we can decrypt the file.
  readInitVect.on('close', () => {
    const cipherKey = getCipherKey(password);
    const readStream = fs.createReadStream(file, { start: 16 });
    const decipher = crypto.createDecipheriv('aes256', cipherKey, initVect);
    const unzip = zlib.createUnzip();
    const writeStream = fs.createWriteStream(file + '.unenc');

    readStream
      .pipe(decipher)
      .pipe(unzip)
      .pipe(writeStream);
  });
}
```

## Part 4: One more thing

I said this would be a CLI program, so let's add one more file:

```plaintext
touch aes.js
```

Let's focus on handling two commands:

```plaintext
node aes.js encrypt ./file.txt myPassword
node aes.js decrypt ./file.txt.enc myPassword
```

These two commands have the same arguments in the same position. We just need to know if we want to encrypt or decrypt some file. Inside `aes.js`:

```js
// import our two functions
const encrypt = require('./encrypt');
const decrypt = require('./decrypt');
// pull the mode, file and password from the command arguments.
const [ mode, file, password ] = process.argv.slice(2);
if (mode === 'encrypt') {
  encrypt({ file, password });
}
if (mode === 'decrypt') {
  decrypt({ file, password });
}
```

You should be able to run the commands we initially set out to support.

## What's next?

There's a lot that could be added, improved, and extended.

### Moar encryption

We really should 'sign' the file using an HMAC algorithm. HMAC, or Hash Message Authentication Code, is a means of verifying the authenticity of a message and that it's contents haven't been tampered with. This would be a simple extension, but this tutorial was already long as heck. You can read more about it [here](http://krytosvirus.com/text/HMAC.htm).

### Error handling

If you enter an incorrect password, the app crashes with an arcane message. We could add some error handling around each of the streams to know precisely which step failed.

### Parameterized encryption algorithms

Node's encryption algorithms are backed by whatever is available in openssl, and there are a lot of them (189 to be exact, you can see them all by entering `openssl list-cipher-algorithms` into your terminal). We could allow a user to choose which algorithm they'd like to use. This would require choosing the correct initialization vector and key size, too.

### Web service?

A bit more more of a lofty goal would be utilizing this code as a personal encrypted butt storage solution, but I'll save that idea for another rainy day.

Thanks for reading!
