# git-sync-s3

Ever get annoyed at how hard it is to manage repo-associated big files? Well this tool is meant to make it stupid-easy. All you need is an aws account. Also, you need `aws-cli` installed. As a recommendation, I would figure out how to use [`aws-vault`](https://github.com/99designs/aws-vault) and use that because `aws-cli`'s base security model is terrible.

This does not work with any other datastore, and will never be changed to work with another datastore. I wanted an uncomplicated tool, and building it with some presumptions (including that aws-s3 would be the backend) would de-complicate the tool and allow for some nice configuration & usage convenience.

### Installation, system-wide

```sh
brew tap dougpagani
brew install dougpagani/git-sync-s3
```

### Installation, into a repo

Go into the target-repo, and run this:

```sh
git sync-s3 install <s3-bucket-name> [--dont-create]
# or, using aws-vault
aws-vault exec <profile> -- git sync-s3 install <s3-bucket-name>
```

You should get a printout of:

```text
AWS Account: -
AWS Bucket: -
AWS User: -
Key ID: -

proceed? [Y/n]: 
```

If all the info looks good, click enter and it will create the bucket.

If you want to automate this as part of a **bootstrap** script for your fellow-devs, then put the install line with a `--dont-create` in the appropriate place in your repo's bootstrap script, and it will just configure git's filter correctly. 

### Usage

Most of these commands can either run repo-wide, or path/file-scoped. You can run the sub-command as either `sync-s3`, `sync`, or `s3`; they were all aliased as such upon install of the script.

#### Overview

```sh
git s3 ls [path]
# git s3 push [path] # I don't think this cmd makes sense, but I'll see
git s3 pull [path]
git s3 track <path> # updates .gitattributes with the appropriate entry; also git-add's

# These are mostly internal, unless you want to test something about it.
git s3 smudge # || deref / download
git s3 clean # || store-or-ignore
git s3 doctor # checks that all currently-s3-referenced files can be found on s3
```

#### List files

```sh
git s3 ls
#> lists both downloaded & uploaded
git s3 ls --dereferenced # || -d
#> lists files that have their real contents in the places you'd expect
git s3 ls --referenced # || -r
#> lists files that are yet to be replaced with the actual contents
git s3 ls [--aforementioned-option] imgs/
#> scopes any of the previous queries to just the imgs/ folder
git s3 ls --dangling
#> returns list of files found on s3 which are not referenced in your current HEAD
```

This uses your `.gitignore` , tries to emulate its glob expansion, and figures out which files are currently dereferenced. Not guaranteed to be perfect unless someone comes along with the knowledge of how to do this in a less-error-prone way.

### Alternatives: Differences between git-sync-s3 and git-lfs

I don't know, I've never used `git-lfs`. Seemed a bit over-complicated while not even having a configurable storage engine.
Here's why I think it is probably overcomplicated: [one](https://blog.dermah.com/2020/05/26/how-to-be-stingy-git-lfs-on-your-own-s3-bucket/), [two](https://dzone.com/articles/git-lfs-why-and-how-to-use), [three](https://stackoverflow.com/questions/41200129/using-git-lfs-with-s3-compatible-storage)

Also there's [`exile`](https://github.com/JayavasanthRamesh/exile) and [`git-exile`](https://github.com/patstam/git-exile), neither of which I also have not used. They seemed to have different intent, though, and decouple git + those large files. `exile` REALLY decouples them, whereas `git-exile` just blurs the line a bit. Also s3 isn't built into either, and you need to maintain the configuration for the storage backend separately, which, is annoying & for my use case unnecessary.

### Advanced + Questions

Q: Help! My s3 bucket is not found!
A: TODO

Q: Can you use a single bucket that already exists?
A: Yes, although you'd be cluttering it w/ a bunch of sha-named-files.

Q: Can you re-use a bucket across different repos?
A: Yes, although you'll be 

Q: Can I use this to download a whole s3 bucket, and sync it to a folder?
A: No, although maybe I do this in the future. I don't see any value in this vs. just having a bucket-and-directory-scoped entrypoint in your own project. 

One possible implementation is to just take an entire folder, and smudge out anything under it. It would be an interesting concept. It could even do something like sync-up your database for local perusal. (i.e. your app publishes certain files to a certain bucket, and you can expose that bucket locally or push stuff up to it via commits). It sort of muddies the line between dev & prod, though, and I'm not sure it is a good abstraction.

Q: Can I dereference all files at once whenever I check-out?
A: Yes, although this can be a bit slow for big repos. To do this, add a `post-checkout` hook which runs `git s3 pull`.

Q: Can I make it optional/manual to upload the files to s3, 
A: No, `git-exile` does this, and I think it's kludgy/awkward, and makes for an unnecessarily bad user experience.

<u>Tips</u>

- You should use `git s3 install --dont-create` as part of your bootstrap script to help your devs update their local `.git/config`.

<u>Understanding the Internals</u>

These two commands should help troubleshoot what's on s3, and what's locally:

- `git s3 doctor` -- get missing refs; ie files which reference an s3

  > this will usually be caused by having the wrong envar for which bucket you need to use.

- `git ls --danglers` -- get objects on s3 which dont have references in the repo

  >  this will usually be caused by re-using the same bucket for not just this repo

These two commands should give you the full picture as to **repo-to-s3** *status-of-synchronization*.

