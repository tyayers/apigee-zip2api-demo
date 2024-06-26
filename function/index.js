// index.js
// ------------------------------------------------------------------
//
// Copyright 2022 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/* jshint esversion:9, node:true, strict:implied */
/* global process, console, Buffer */

const functions = require('@google-cloud/functions-framework');
const AdmZip   = require('adm-zip');
const textSuffixes = ['.js', '.json', '.txt', '.md', '.yaml', '.xml', '.xsl', '.wsdl', '.html'];

const base64Decode = (b64EncodedBuf) => Buffer.from(b64EncodedBuf.toString('utf8'), 'base64');
const isTextFile = n => textSuffixes.find(s => n.endsWith(s));
const jsonFormat = entry => {
        let name = entry.entryName,
            encoding = (isTextFile(name)) ? 'utf8' : 'base64',
            b = entry.getData(),
            r = {
              name,
              stamp: entry.header.time,
              contents: b.toString(encoding)
            };
        return r;
      };
const invalidRequest = res => res.status(400).type('text/plain').send('invalid request');

functions.http('zip-ops-handler', async (req, res) => {
  if ('POST' != req.method) {
    invalidRequest(res);
    return;
  }

  // Start with binary data, if it was sent
  let contents = req.rawBody;

  // If the user sent a fileUrl, then download it as a buffer and use that
  let url = req.query["fileUrl"];
  if (url) {
    console.log(url);
    let fileContents = await fetch(url);
    contents = Buffer.from(await fileContents.arrayBuffer());
  }

  // If the content-type is JSON or text, decode to a buffer
  if (req.is('application/json')) {
    contents = base64Decode(req.body.contents);
  }
  else if (req.is('text/plain')) {
    contents = base64Decode(req.rawBody);
  }

  if ( ! contents) {
    invalidRequest(res);
    return;
  }

  const result = new AdmZip(contents).getEntries().map(jsonFormat);
  res.send({result});

});
