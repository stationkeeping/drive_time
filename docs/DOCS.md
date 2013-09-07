### Drive Time

Drive Time allows you to map a Google Spreadsheet to a your Rails database. Each worksheet represents a different Model class; its columns represent the model's attributes and each row represents a different instance. It is designed to make as many allowances for the person authoring the spreadsheet so it can be used as a bridge between a non-technical user and yourself. Unless they are an idiot, in which case you're still screwed.

*I am using it sucessfully in two projects at the moment, however there are may well be some things that will cause issues that I haven't needed come accross yet.*

#### Installation

You know the drill. Add `gem drive_time` to your `Gemfile` and run `$ bundle`.

#### Prerequisits

Drive Time uses the [Google Drive](https://github.com/gimite/google-drive-ruby) gem, which handles the connection to Google Drive, the download and transforms the Spreadsheet and Worksheet into Ruby objects. It relies on the presence of two envs:

```
GOOGLE_USERNAME=your.email@gmail.com
GOOGLE_PASSWORD=YourPassword
```

You will also need a Rails project with a migrated datbase, ready to recieve the generated models.

#### Using Drive Time

Drive Time needs access to your Rails project. You can run it as part of the seeding process, or directly using `$ rails runner`.

An example of usage:

```
include DriveTime

mappings_path = File.join(File.dirname(__FILE__),'mappings.yml')
SpreadsheetsConverter.new.load mappings_path
```

The `mappings.yml` is crucial. It specifies the name of your spreadsheet and how you want to map your worksheets to your models.

##### Mappings

A bare-bones mapping might look like this:

```
spreadsheets:
- title: Business
  worksheets:
    - title: Company
      key: name
      fields:
        - name: name
        - name: description
      associations:
        - name: learning_group
```

Drive Time will look for a spreadsheet called 'Business' and download it. It will then find a spreadsheet within called 'Company' and run through each row, generating a new model of class `Company` with attributes of `name` and `description`.

The `key` is a unique identifier which is used internally to identify the models and is used within the spreadsheets to declare associations. In this case we are declaring that we want to use the name field as the key. The crucial thing is that the key is unique amongst all models of that type. If no attributes are guarenteed to be unique, one option is to add an explicit `key` column, containing a unique identifier to the spreadsheet, however this is unwealdy and easy to lose track of. A better option is to use multiple attributes to generate the key. This can be done using a builder:

```
  worksheets:
    - title: Company
      key:
        builder: join
        from_fields: [name, city]
```

This will result in a key made from the company name and city combined. This is great for giving models of the same type a unique key, but requires more thought if the id will be used by other models to declare associations.

*Note: Internally, keys are just downcased, underscored and whitespace-stripped versions of whater value is ussed for the key.*

##### Associations

Below an association is declared between the `Company` and the `Product`. It is declared as a singular relationship using the `singular` mapping attribute.

Drive Time assumes that if a worksheet declares a singular attribute mapping, it will contain a column named after the model. This field should contain the key of the instance of the model that it will use to satisfy its dependency. In the example below it would contain the sku of the `Product` model.

```
spreadsheets:
- title: Business
  worksheets:
    - title: Company
     key: name
     fields:
       - name: name
       - name: description
     associations:
       - name: Product
       - singular: true
    - title: Product
     key: sku
     fields:
       - name: title
       - name: sku
       - name: price
```

One-to-many relationships can be declared in two ways.

If there are only a few possible options, a column can be assigned to each option and named after the option. For example if a company had one or more Regions from either Europe, or Asia or America, and we were using the name field for the Region key, we could add three columns to the Company spreadsheet named 'Europe', 'Asia', and 'America'. If we want to add that region we would add a value of 'Yes' to the field:

```
associations:
  - name: region
    builder: use_fields
    field_names: [europe, asia, america]
```

Another option, appropriate for situations where there are many possible values, is to declare an inverted relationship. for example, if you had a 'Team' that had many 'Players', rather than declaring the team's players in the team Spreadsheet, you could declare each Player's team in a column in the Player Spreadsheet. For this to work, you must declare the relationship inverse. So in the Player worksheet mapping:

```
associations:
  - name: team
    inverse: true
```

A polymorphic association can be declared using:

```
associations:
  - name: team
    polymorphic:
      association: contactable
```

It is OK to mix 'polymorphic' and 'singular' for the same association.

Using Google Spreadsheet's data validations can make things much easier on the Spreadsheet end. You can effectively add dropdowns containing values from a fixed list or from another Worksheet column, making sure that only valid values can be added.


##### Other features

If you want to map a database field to a differently named field on a model you can use the following:

```
fields:
  - name: name
    map_to: title
```

This will map a Worksheet field named 'name' to a model attribute named 'title'.

You can also map the Worksheet title to a differently named model:

```
worksheets:
    - title: Staff
      map_to_class: Employee
```

This will use the Worksheet named 'Staff' to a model called 'Employee'.

It is sometimes useful to generate a UID for models to use in linked to an image or icon resource. You can map the model's key to a model attribute using:

```
- title: Example
  key: title
  key_to: uid
```





