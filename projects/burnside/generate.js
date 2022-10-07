// Generate all necklaces of length n from alphabet [0, …, k - 1].
// Algorithm due to Fredricksen, Kessler and Maiorana.
function generate_necklaces(n, k) {
  var necklaces = [],
      a = [],
      i = -1,
      j;
  while (++i < n) a[i] = 0;
  necklaces.push(a.slice());
  while (1) {
    i = n;
    while (--i >= 0) if (a[i] < k - 1) break;
    if (i < 0) break;
    a[j = i++]++;
    while (++j < n) a[j] = a[j % i];
    if (n % i === 0) necklaces.push(a.slice());
  }
  return necklaces;
}

// Algorithm due to Joe Sawada, "Generating Bracelets in constant amortized
// time", SIAM Journal on Computing archive Volume 31 , Issue 1 (2001).
function generate_bracelets(n, k) {
  var a = [],
      i = -1;
  while (++i < n) a[i] = 0;
  return genb(1, 1, 1, -1, 0, false);

  function genb(t, p, r, u, v, rs) {
    var result = [];
    if (t - 1 > (n - r) / 2 + r) {
      if (a[t - 1] > a[n - t + 2 + r]) rs = false;
      else if (a[t - 1] < a[n - t + 2 + r]) rs = true;
    }
    if (t > n) {
      if (!rs && n % p === 0) result.push(a.slice(1));
    } else {
      a[t] = a[t - p];
      v = a[t] === a[1] ? v + 1 : 0;

      if (u === -1 && a[t - 1] !== a[1]) u = r = t - 2;
      if (u === -1 || t !== n || a[n] !== a[1]) {
        if (u === v) {
          var rev = checkrev(t, u);
          if (rev !== -1) result = result.concat(genb(t + 1, p, rev ? t : r, u, v, rev ? false : rs));
        } else result = result.concat(genb(t + 1, p, r, u, v, rs));
      }
      for (var j = a[t - p] + 1; j < k; j++) {
        a[t] = j;
        result = result.concat(genb(t + 1, t , r, u, 0, rs));
      }
    }
    return result;
  }

  function checkrev(t, i) {
    while (++i < (t + 1) / 2 + 1) {
      if (a[i] < a[t - i + 1]) return 0;
      if (a[i] > a[t - i + 1]) return -1;
    }
    return 1;
  }
}
