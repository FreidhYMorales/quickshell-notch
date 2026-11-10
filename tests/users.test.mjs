import { test } from "node:test";
import assert from "node:assert/strict";
import { defaultUser, humanUsers } from "../shell/logic/users.mjs";

const PASSWD = [
  "root:x:0:0:root:/root:/bin/bash",
  "nobody:x:65534:65534:nobody:/:/usr/bin/nologin",
  "systemd-network:x:980:980::/:/usr/bin/nologin",
  "deadlock:x:1000:1000:Deadlock:/home/deadlock:/bin/zsh",
  "invitado:x:1001:1001:Invitado,,,:/home/invitado:/bin/sh",
  "sin-shell:x:1002:1002:Sin Shell:/home/nada:/usr/bin/false",
  "duplicado:x:1000:1000:Duplicado:/home/duplicado:/bin/bash",
].join("\n");

test("lists selectable human accounts with their real name", () => {
  assert.deepEqual(humanUsers(PASSWD), [
    { name: "deadlock", displayName: "Deadlock" },
    { name: "invitado", displayName: "Invitado" },
  ]);
});

test("ignores malformed lines, comments and missing fields", () => {
  const text = "# comentario\nbasura\n:x:1000:1000::/home/x:/bin/sh\n";
  assert.deepEqual(humanUsers(text), []);
});

test("an account without a GECOS name falls back to its user name", () => {
  const text = "pelado:x:1000:1000::/home/pelado:/bin/bash";
  assert.deepEqual(humanUsers(text), [
    { name: "pelado", displayName: "pelado" },
  ]);
});

test("preselects the given user, then the first account, then nothing", () => {
  const users = humanUsers(PASSWD);
  assert.equal(defaultUser(users, "invitado"), "invitado");
  assert.equal(defaultUser(users, "root"), "deadlock");
  assert.equal(defaultUser(users, ""), "deadlock");
  assert.equal(defaultUser([], "invitado"), "");
});
