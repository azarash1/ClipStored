.PHONY: build run clean

build:
	swift build -c release --product ClipStored

run:
	swift run ClipStored

clean:
	swift package clean
	rm -rf .build

# Create an application bundle
app:
	mkdir -p ClipStored.app/Contents/MacOS
	mkdir -p ClipStored.app/Contents/Resources
	cp .build/release/ClipStored ClipStored.app/Contents/MacOS/
	cp Sources/ClipStored/Resources/Info.plist ClipStored.app/Contents/
	@echo "App bundle created at ./ClipStored.app"
	@echo "You can now copy this to your Applications folder."

install: app
	cp -R ClipStored.app /Applications/
	@echo "ClipStored has been installed to your Applications folder."

uninstall:
	rm -rf /Applications/ClipStored.app
	@echo "ClipStored has been uninstalled." 