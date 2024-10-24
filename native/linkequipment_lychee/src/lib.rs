use lychee_lib::{Collector, Input, InputSource, Request, Result};
use reqwest::Url;
use rustler::NifStruct;
use tokio_stream::StreamExt;

#[derive(Debug, NifStruct)]
#[module = "LinkEquipment.Link"]
struct Link {
    url: Uri,
    source: Uri,
    element: Option<String>,
    attribute: Option<String>,
}

impl From<Request> for Link {
    fn from(value: Request) -> Self {
        let source = match value.source {
            InputSource::RemoteUrl(url) => *url,
            _ => panic!("only remote urls supported"),
        };

        Self {
            url: Url::parse(value.uri.as_str()).unwrap().into(),
            source: source.into(),
            element: value.element,
            attribute: value.attribute,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "URI"]
struct Uri {
    authority: Option<String>,
    fragment: Option<String>,
    host: Option<String>,
    path: Option<String>,
    port: Option<u16>,
    query: Option<String>,
    scheme: Option<String>,
    userinfo: Option<String>,
}

impl From<reqwest::Url> for Uri {
    fn from(value: reqwest::Url) -> Self {
        Self {
            authority: value.domain().map(str::to_string),
            fragment: None,
            host: value.domain().map(str::to_string),
            path: Some(value.path().to_string()),
            port: value.port(),
            query: value.query().map(str::to_string),
            scheme: Some(value.scheme().to_string()),
            userinfo: None,
        }
    }
}

async fn do_collect_links(url: Url) -> Result<Vec<Request>> {
    // Collect all links from the following inputs
    let inputs = vec![Input {
        source: InputSource::RemoteUrl(Box::new(url)),
        file_type_hint: None,
        excluded_paths: None,
    }];

    Collector::new(None) // base
        .skip_missing_inputs(false) // don't skip missing inputs? (default=false)
        .use_html5ever(false) // use html5ever for parsing? (default=false)
        .collect_links(inputs) // base url or directory
        .collect::<Result<Vec<_>>>()
        .await
}

#[rustler::nif]
fn collect_links(url: String) -> std::result::Result<Vec<Link>, ()> {
    let url = Url::parse(&url).unwrap();
    let rt = tokio::runtime::Runtime::new().unwrap();
    let future = do_collect_links(url);
    let result = rt.block_on(future);

    match result {
        Result::Ok(links) => Ok(links.into_iter().map(Link::from).collect::<Vec<_>>()),
        Result::Err(_) => Err(()),
    }
}

rustler::init!("Elixir.LinkEquipment.Lychee");
